import os

from pyiceberg.catalog import load_catalog
from pyiceberg.expressions import LessThan, GreaterThanOrEqual, And
from datetime import datetime, UTC, timedelta

def main():
    
    # loads Tableflow catalog from Confluent cloud
    catalog = load_catalog(name="default")
    ns = catalog.list_namespaces()
    print(ns)

    # loads table from Confluent cloud
    namespace = os.getenv('TABLEFLOW_NAMESPACE')
    table_name = os.getenv('TABLEFLOW_TABLE')
    table = catalog.load_table(f"{namespace}.{table_name}")

    print(table)

    # scans reads data needed to be exported and stores in Pandas dataframe for manipulation
    scan = table.scan(
      row_filter=And(
          GreaterThanOrEqual("$$timestamp",datetime.now(UTC) - timedelta(minutes=20)),
          LessThan("$$timestamp",datetime.now(UTC))
        ),
      # Columns you want to filter on needs to be selected
      selected_fields=("$$timestamp", "store_order_id", "userid", "gender", "date","order_lines"),
    )

    pd = scan.to_pandas()
    print(pd.head())

    # offloads data to a flat file to a destination for instance S3
    pd.to_csv(f's3://dev-pizza-orders-poc/filtered_orders_{datetime.now(UTC).strftime('%Y-%m-%d_%H-%M-%S')}.csv')

    # # if SQL preferred DuckDB is the way to go, DuckDB is embedded OLAP database, like SQlite 
    # # TODO: resolve timezone error issues "errorMessage": "'/etc/localtime'", "errorType": "UnknownTimeZoneError",

    # con = scan.to_duckdb(table_name="orders_2_4")
    # print(
    #     con.execute(
    #         'SELECT "$$timestamp","ordertime", "orderid", "orderunits", "itemid" FROM orders_2_4 ORDER BY orderid DESC LIMIT 5'
    #     ).fetchall()
    # )




if __name__ == '__main__':
    main()

