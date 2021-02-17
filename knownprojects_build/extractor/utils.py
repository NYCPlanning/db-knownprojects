import pandas as pd
import geopandas as gpd
import hashlib
import csv
from io import StringIO
from functools import wraps
from . import engine


def psql_insert_copy(table, conn, keys, data_iter):
    """
    Execute SQL statement inserting data
    Parameters
    ----------
    table : pandas.io.sql.SQLTable
    conn : sqlalchemy.engine.Engine or sqlalchemy.engine.Connection
    keys : list of str
        Column names
    data_iter : Iterable that iterates the values to be inserted
    """
    # gets a DBAPI connection that can provide a cursor
    dbapi_conn = conn.connection
    with dbapi_conn.cursor() as cur:
        s_buf = StringIO()
        writer = csv.writer(s_buf)
        writer.writerows(data_iter)
        s_buf.seek(0)

        columns = ", ".join('"{}"'.format(k) for k in keys)
        if table.schema:
            table_name = "{}.{}".format(table.schema, table.name)
        else:
            table_name = table.name

        sql = "COPY {} ({}) FROM STDIN WITH CSV".format(table_name, columns)
        cur.copy_expert(sql=sql, file=s_buf)


def hash_each_row(df: pd.DataFrame) -> pd.DataFrame:
    """
    e.g. df = hash_each_row(df)
    this function will create a "uid" column with hashed row values
    ----------
    df: input dataframe
    """
    df["temp_column"] = df.astype(str).values.sum(axis=1)
    hash_helper = lambda x: hashlib.md5(x.encode("utf-8")).hexdigest()
    df["uid"] = df["temp_column"].apply(hash_helper)
    del df["temp_column"]
    return df


def format_field_names(df: pd.DataFrame) -> pd.DataFrame:
    df.columns = df.columns.map(lambda x: x.lower().replace("-", "_").replace(" ", "_"))
    return df


def ETL(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        name=func.__name__
        print(f"ingesting {name} ...")
        df = func()

        # Adding uid
        df = hash_each_row(df)

        # Formating field names
        df = format_field_names(df)

        # Write to postgres database
        ## If it's a geopandas dataframe, we will have to
        ## Convert geometry column to text first
        if isinstance(df, gpd.geodataframe.GeoDataFrame):
            df = pd.DataFrame(df, dtype=str)

        print(f"export {name} to postgres ...")
        df.to_sql(
            name,
            con=engine,
            if_exists="replace",
            index=False,
            method=psql_insert_copy,
        )

        if "geom" in df.columns:
            engine.execute("""
            BEGIN; 
            ALTER TABLE %(name)s 
            ALTER COLUMN geometry type Geometry 
                USING ST_SetSRID(ST_GeomFromText(geometry), 4326);
            COMMIT;
            """ % {"name":name})
        print("🎉 done!")
        return None

    return wrapper
