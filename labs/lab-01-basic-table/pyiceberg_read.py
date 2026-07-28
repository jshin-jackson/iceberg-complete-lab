"""PyIceberg HMS 조회 예제 (선택)."""
from pyiceberg.catalog import load_catalog

# 환경에 맞게 uri 수정
catalog = load_catalog(
    "hive_prod",
    **{
        "type": "hive",
        "uri": "thrift://REPLACE_HMS_HOST:9083",
        "warehouse": "ofs://ozone1784520717/vol1/bucket1/warehouse",
    },
)
table = catalog.load_table("iceberg_lab.customers")
print(table.schema())
print(len(list(table.scan().to_arrow())))
