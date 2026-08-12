from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.postgres.operators.postgres import PostgresOperator
import clickhouse_connect
from airflow.hooks.base import BaseHook

from datetime import datetime
import requests
import pandas as pd
import time


pg_conn_id_af = 'pg' #соединение pg из af
ch_conn_id_af = 'ch' #соединение ch из af
season = 2024 #год для загрузки
url_api = 'https://api.openf1.org/v1' 
time_delay  = 2.0
sql_dir = '/home/admin1/f1_proj'


load_meetings = True
load_sessions = False 
load_drivers = False
load_laps = False
load_stints = False
load_pit = False
load_weather = False
load_race_control = False
load_session_result = False
load_start_grid = False
load_overtake = False
load_posit = False
pos_teams = False
pos_drivers = False

#Выбор по типу сессии для загрузки. 
session_types_filter = ['Race','Qualifying'] 
#session_types_filter = None 

    
def make_api_request(endpoint, params):
    url = f"{url_api}/{endpoint}"
    try:
        print(f"{url}: {params}")
        response = requests.get(url, params=params, timeout=10)
        data = response.json()
        time.sleep(time_delay)
        return data
        
    except Exception as e:
        print(f"Ошибка {endpoint}: {str(e)[:200]}")
        return []


def flatten_arrays_in_df(df):

# в ситуациях когда в рамках одного круга были красные флаги, время круга в апи передается массивом(время до флага и после). обработаем такое

    for col in df.columns:
        sample = df[col].dropna() # удаляем non'Ы
        if sample.empty: #пропускаем пустую колонку
            continue
        
        has_lists = sample.apply(lambda x: isinstance(x, list)).any() #пытаемся ускорить, пропустим колонки где внутри нет массива для суммирования
        if not has_lists:
            continue
        
        def flatten_value(val):
            #if val is None or (isinstance(val, float) and pd.isna(val)):
            #    return None
            if isinstance(val, list): #если массив
                if len(val) == 0: #пустой массив
                    return None
                if len(val) == 1: #один элемент внутри
                    return val[0]
                try:
                    return sum(val) #Суммируем массив.
                except TypeError:
                    return val[0]
            return val
        
        df[col] = df[col].apply(flatten_value)
    
    return df


def clean_numeric_columns(df, columns_to_clean=None):
#Очистка числовых полей от нечисловых значений. в полях где передается разрыв между гонщиками, передается значени +1 круг, заменим на пустоту
    if columns_to_clean is None:
        return df
    
    for col in columns_to_clean:
        if col in df.columns:
            try:
                df[col] = pd.to_numeric(df[col], errors='coerce')
            except Exception:
                pass
    return df


def load_to_postgres(df, table_name, numeric_columns=None):
    if df is None or df.empty:
        return
    df = flatten_arrays_in_df(df.copy())
    df = clean_numeric_columns(df, numeric_columns)
    hook = PostgresHook(postgres_conn_id=pg_conn_id_af)
    hook.run(f"TRUNCATE {table_name}") 
    hook.insert_rows( 
        table=table_name,
        rows=df.values.tolist(),
        target_fields=df.columns.tolist(),
        commit_every=5000,
    )


def extract_meetings(**kwargs):
    if not load_meetings:
        return []
    data = make_api_request('meetings', {'year': season })
    df = pd.DataFrame(data)[['meeting_key', 'meeting_name', 'country_name', 'country_code', 'circuit_key', 'circuit_short_name', 'date_start', 'year']]
    load_to_postgres(df, 'staging.dim_meeting')


def extract_sessions(**kwargs):
    if not load_sessions:
        return []
    
    data = make_api_request('sessions', {'year': season})
    
    # в БД запишем все сессии, но потом отфильтруем для быстроты загрузки
    df = pd.DataFrame(data)
    required_cols = ['session_key', 'meeting_key', 'session_name', 'session_type', 'date_start', 'date_end', 'is_cancelled']
    for col in required_cols:
        if col not in df.columns:
            df[col] = None
    df = df[required_cols]
    
    load_to_postgres(df, 'staging.dim_session')
    
    if session_types_filter: #фильтруем сессии
        filtered_keys = [
            row['session_key'] 
            for row in data
            if row.get('session_type') in session_types_filter
        ]
        return filtered_keys
    else:
        return [row['session_key'] for row in data]


def extract_drivers(**kwargs):
    if not load_drivers:
        return
    session_keys = kwargs['ti'].xcom_pull(task_ids='extract_sessions') or []
    all_drivers = []
    
    for session_key in session_keys:
        try:
            data = make_api_request('drivers', {'session_key': session_key})
            all_drivers.extend(data)
        except Exception:
            continue
            
    if not all_drivers:
        return 
    
    df = pd.DataFrame(all_drivers).drop_duplicates(subset=['driver_number','meeting_key'])
    df = df[['driver_number', 'broadcast_name', 'first_name', 'last_name', 'full_name', 'name_acronym', 'country_code', 'team_name', 'team_colour', 'headshot_url', 'meeting_key']]
    load_to_postgres(df, 'staging.dim_driver')

    return [row['driver_number'] for row in data]

def extract_laps(**kwargs):
    if not load_laps:
        return
    session_keys = kwargs['ti'].xcom_pull(task_ids='extract_sessions') or []
    drivers_keys = kwargs['ti'].xcom_pull(task_ids='extract_drivers') or []
    all_laps = []
    
    for session_key in session_keys:
        for driver_number in drivers_keys:
            payload = {'session_key': session_key, 'driver_number':driver_number}
            all_laps.extend(make_api_request('laps', payload))


    #for session_key in session_keys:
    #    all_laps.extend(make_api_request_for_laps('laps', {'session_key': session_key}))
    
    if not all_laps:
        return
        
    df = pd.DataFrame(all_laps)
    
    required_cols = [
        'session_key', 'meeting_key', 'driver_number', 'lap_number', 
        'lap_duration', 'duration_sector_1', 'duration_sector_2', 'duration_sector_3',
        'stint_number', 'compound', 'tyre_age_at_start', 'is_pit_out_lap'
    ]
    
    for col in required_cols:
        if col not in df.columns:
            df[col] = None
            
    df = df[required_cols]
    
    load_to_postgres(df, 'staging.fct_laps')


def extract_stints(**kwargs):
    if not load_stints:
        return
    session_keys = kwargs['ti'].xcom_pull(task_ids='extract_sessions') or []
    all_stints = []
    for session_key in session_keys:
        try:
            all_stints.extend(make_api_request('stints', {'session_key': session_key}))
        except Exception:
            continue
    df = pd.DataFrame(all_stints)[['session_key', 'meeting_key', 'driver_number', 'stint_number', 'lap_start', 'lap_end', 'compound', 'tyre_age_at_start']]
    load_to_postgres(df, 'staging.fct_stints')


def extract_pit(**kwargs):
    if not load_pit:
        return
    session_keys = kwargs['ti'].xcom_pull(task_ids='extract_sessions') or []
    all_pits = []
    for session_key in session_keys:
        try:
            all_pits.extend(make_api_request('pit', {'session_key': session_key}))
        except Exception:
            continue
    df = pd.DataFrame(all_pits)[['session_key', 'meeting_key', 'driver_number', 'lap_number', 'pit_duration', 'stop_duration']]
    load_to_postgres(df, 'staging.fct_pit')


def extract_weather(**kwargs):
    if not load_weather:
        return
    session_keys = kwargs['ti'].xcom_pull(task_ids='extract_sessions') or []
    all_weather = []
    for session_key in session_keys:
        try:
            all_weather.extend(make_api_request('weather', {'session_key': session_key}))
        except Exception:
            continue
    df = pd.DataFrame(all_weather)[['session_key', 'meeting_key', 'date', 'air_temperature', 'track_temperature', 'humidity', 'pressure', 'wind_speed', 'wind_direction', 'rainfall']]
    load_to_postgres(df, 'staging.fct_weather')


def extract_race_control(**kwargs):
    if not load_race_control:
        return
    session_keys = kwargs['ti'].xcom_pull(task_ids='extract_sessions') or []
    all_rc = []
    for session_key in session_keys:
        try:
            all_rc.extend(make_api_request('race_control', {'session_key': session_key}))
        except Exception:
            continue
    df = pd.DataFrame(all_rc)[['session_key', 'meeting_key', 'date', 'category', 'flag', 'message', 'driver_number', 'lap_number']]
    load_to_postgres(df, 'staging.fct_race_control')


def extract_overtakes(**kwargs):
    if not load_overtake:
        return

    session_keys = kwargs['ti'].xcom_pull(task_ids='extract_sessions') or []
    all_overtakes = []


    for i, session_key in enumerate(session_keys, 1):
        try:
            data = make_api_request('overtakes', {'session_key': session_key})
            all_overtakes.extend(data)              
        except Exception as e:
            continue

    df = pd.DataFrame(all_overtakes)
    load_to_postgres(df, 'staging.fct_overtakes')


def extract_position(**kwargs):
    if not load_posit:
        return
    
    session_keys = kwargs['ti'].xcom_pull(task_ids='extract_sessions') or []
    all_positions = []


    for i, session_key in enumerate(session_keys, 1):
        try:
            data = make_api_request('position', {'session_key': session_key})
            all_positions.extend(data)          
        except Exception as e:
            continue

    df = pd.DataFrame(all_positions)

    load_to_postgres(df, 'staging.fct_position')

def extract_session_result(**kwargs):
    if not load_session_result:
        return
    
    session_keys = kwargs['ti'].xcom_pull(task_ids='extract_sessions') or []
    all_data = []

    for i, session_key in enumerate(session_keys, 1):
        try:
            data = make_api_request('session_result', {'session_key': session_key})
            all_data.extend(data)
        except Exception as e:
            continue

    if not all_data:
        return

    df = pd.DataFrame(all_data)

    required_cols = ['session_key', 'meeting_key', 'driver_number', 'position', 
                     'number_of_laps', 'duration', 'gap_to_leader', 
                     'dnf', 'dns', 'dsq', 'points']
    for col in required_cols:
        if col not in df.columns:
            df[col] = None
    df = df[required_cols]

    load_to_postgres(
        df, 
        'staging.fct_session_result',
        numeric_columns=['duration', 'gap_to_leader', 'dnf']
    )


def extract_starting_grid(**kwargs):
    if not load_start_grid:
        return
    
    session_keys = kwargs['ti'].xcom_pull(task_ids='extract_sessions') or []
    
    all_data = []


    for i, session_key in enumerate(session_keys, 1):
        try:
            data = make_api_request('starting_grid', {'session_key': session_key})
            all_data.extend(data)
                    
        except Exception as e:
            continue


    df = pd.DataFrame(all_data)

    load_to_postgres(df, 'staging.fct_starting_grid')


def extract_championship_drivers(**kwargs):
    if not pos_drivers:
        return
    
    session_keys = kwargs['ti'].xcom_pull(task_ids='extract_sessions') or []
    
    all_data = []


    for i, session_key in enumerate(session_keys, 1):
        try:
            data = make_api_request('championship_drivers', {'session_key': session_key})
            all_data.extend(data)

        except Exception as e:
            continue

    df = pd.DataFrame(all_data)

    load_to_postgres(df, 'staging.fct_championship_drivers')


def extract_championship_teams(**kwargs):
    if not pos_teams:
        return
    
    session_keys = kwargs['ti'].xcom_pull(task_ids='extract_sessions') or [] 
    all_data = []


    for i, session_key in enumerate(session_keys, 1):
        try:
            data = make_api_request('championship_teams', {'session_key': session_key})
            all_data.extend(data)

        except Exception as e:
            continue


    df = pd.DataFrame(all_data)
    load_to_postgres(df, 'staging.fct_championship_teams')

def query_clickhouse():

    conn = BaseHook.get_connection(ch_conn_id_af)
    host = conn.host
    port = conn.port
    username = conn.login
    password = conn.password
    database = conn.schema
    
    extra = conn.extra_dejson
    secure = extra.get('secure', False)
    
    client = clickhouse_connect.get_client(
        host=host,
        port=port,
        username=username,
        password=password,
        database=database,
        secure=secure
    )


    result = client.query('select version()')
    print(f"ClickHouse version: {result.result_rows}")
    client.close()
    



default_args = {
    'owner': 'makogonyua',
    'depends_on_past': False,
    'start_date': datetime(2026, 8, 1),
}

with DAG(
    dag_id='read_api_write_pg',
    default_args=default_args,
    schedule=None,
    catchup=False,

    template_searchpath=sql_dir
) as dag:
    
    init_db_task = PostgresOperator(
        task_id='init_db_stg_ods',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/init_db_stg_ods.sql'
    )

    meetings_task = PythonOperator(
        task_id='extract_meetings', 
        python_callable=extract_meetings)

    sessions_task = PythonOperator(
        task_id='extract_sessions', 
        python_callable=extract_sessions)

    drivers_task = PythonOperator(
        task_id='extract_drivers', 
        python_callable=extract_drivers)

    db_md_task = PostgresOperator(
        task_id='md_ods',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/md_ods.sql'
    )
    
    laps_task = PythonOperator(
        task_id='extract_laps', 
        python_callable=extract_laps)

    db_laps_ods_task = PostgresOperator(
        task_id='laps_ods',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/fct_laps_ods.sql'
    )

    stints_task = PythonOperator(
        task_id='extract_stints', 
        python_callable=extract_stints)

    db_stints_ods_task = PostgresOperator(
        task_id='stints_ods',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/fct_stints_ods.sql'
    )

    pit_task = PythonOperator(
        task_id='extract_pit', 
        python_callable=extract_pit)
    
    db_pit_ods_task = PostgresOperator(
        task_id='pit_ods',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/fct_pit_ods.sql'
    )

    weather_task = PythonOperator(
        task_id='extract_weather', 
        python_callable=extract_weather)

    db_weather_ods_task = PostgresOperator(
        task_id='weather_ods',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/fct_weather_ods.sql'
    )

    race_control_task = PythonOperator(
        task_id='extract_race_control', 
        python_callable=extract_race_control)

    db_race_control_ods_task = PostgresOperator(
        task_id='race_control_ods',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/fct_race_control_ods.sql'
    )

    overtakes_task = PythonOperator(
        task_id='extract_overtakes', 
        python_callable=extract_overtakes)

    db_overtakes_ods_task = PostgresOperator(
        task_id='overtakes_ods',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/fct_overtakes_ods.sql'
    )

    position_task = PythonOperator(
        task_id='extract_position', 
        python_callable=extract_position)

    db_position_ods_task = PostgresOperator(
        task_id='position_ods',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/fct_position_ods.sql'
    )

    session_result_task = PythonOperator(
        task_id='extract_session_result', 
        python_callable=extract_session_result)

    db_session_result_ods_task = PostgresOperator(
        task_id='session_result_ods',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/fct_session_result_ods.sql'
    )

    starting_grid_task = PythonOperator(
        task_id='extract_starting_grid', 
        python_callable=extract_starting_grid)

    db_starting_grid_ods_task = PostgresOperator(
        task_id='starting_grid_ods',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/fct_starting_grid_ods.sql'
    )

    championship_drivers_task = PythonOperator(
        task_id='extract_championship_drivers', 
        python_callable=extract_championship_drivers)

    db_championship_drivers_ods_task = PostgresOperator(
        task_id='championship_drivers_ods',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/championship_drivers_ods.sql'
    )

    championship_teams_task = PythonOperator(
        task_id='extract_championship_teams', 
        python_callable=extract_championship_teams)

    db_championship_teams_ods_task = PostgresOperator(
        task_id='championship_teams_ods',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/championship_teams_ods.sql'
    )

    db_init_dds = PostgresOperator(
        task_id='init_db_dds',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/init_db_dds.sql'
    )

    db_load_dds = PostgresOperator(
        task_id='load_db_dds',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/load_dds.sql'
    )

    db_init_dm = PostgresOperator(
        task_id='init_db_dm',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/init_db_dm_pg.sql'
    )

    db_load_dm = PostgresOperator(
        task_id='load_db_dm',
        postgres_conn_id=pg_conn_id_af,
        sql='sql/load_dm_pg.sql'
    )

    check_version = PythonOperator(
        task_id='check_version',
        python_callable=query_clickhouse
    )


    init_db_task >> meetings_task >> sessions_task
    sessions_task >> drivers_task >> db_md_task
    sessions_task >> laps_task >>  db_laps_ods_task
    sessions_task >> stints_task >>  db_stints_ods_task
    sessions_task >> pit_task >> db_pit_ods_task
    sessions_task >> weather_task >>  db_weather_ods_task
    sessions_task >> race_control_task >> db_race_control_ods_task
    sessions_task >> overtakes_task >>  db_overtakes_ods_task
    sessions_task >> position_task >>  db_position_ods_task
    sessions_task >> session_result_task >> db_session_result_ods_task
    sessions_task >> starting_grid_task >>  db_starting_grid_ods_task
    sessions_task >> championship_drivers_task >> db_championship_drivers_ods_task
    sessions_task >> championship_teams_task >> db_championship_teams_ods_task
    [db_md_task, db_laps_ods_task, db_stints_ods_task, db_pit_ods_task, db_weather_ods_task, db_race_control_ods_task,
    db_overtakes_ods_task, db_position_ods_task, db_session_result_ods_task, db_starting_grid_ods_task, db_championship_drivers_ods_task,
    db_championship_teams_ods_task
    ] >> db_init_dds >> db_load_dds >> db_init_dm >> db_load_dm >> check_version