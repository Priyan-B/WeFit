import os
from dotenv import load_dotenv
import mysql.connector
from mysql.connector import pooling

load_dotenv()

class DB:
    _pool = None

    @classmethod
    def init_pool(cls):
        if cls._pool is None:
            cls._pool = pooling.MySQLConnectionPool(
                pool_name="wefit_pool",
                pool_size=5,
                host=os.getenv("MYSQL_HOST", "localhost"),
                port=int(os.getenv("MYSQL_PORT", "3306")),
                user=os.getenv("MYSQL_USER", "wefit_user"),
                password=os.getenv("MYSQL_PASSWORD", "wefit_pass"),
                database=os.getenv("MYSQL_DATABASE", "wefit_db"),
                autocommit=True,
            )

    @classmethod
    def get_conn(cls):
        if cls._pool is None:
            cls.init_pool()
        return cls._pool.get_connection()

    @staticmethod
    def call_proc(proc_name, args=()):
        conn = DB.get_conn()
        try:
            cur = conn.cursor(dictionary=True)
            cur.callproc(proc_name, args)
            # Collect result sets if any
            results = []
            for result in cur.stored_results():
                results.extend(result.fetchall())
            cur.close()
            return results
        finally:
            conn.close()

    @staticmethod
    def execute(query, params=None):
        conn = DB.get_conn()
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute(query, params or ())
            if cur.with_rows:
                rows = cur.fetchall()
            else:
                rows = []
            cur.close()
            return rows
        finally:
            conn.close()
