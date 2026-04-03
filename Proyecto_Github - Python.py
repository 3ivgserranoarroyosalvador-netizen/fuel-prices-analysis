import pandas as pd
import mysql.connector

conexion = mysql.connector.connect(
    host = "127.0.0.1",
    port = 3306,
    user = "root",
    password = "",
    database = "fuel_prices_portafolio"
)

#Observar tabla
cursor = conexion.cursor()
cursor.execute("SHOW TABLES")
tablas = [t[0] for t in cursor.fetchall()]
print(tablas)

for tabla in tablas:
    df = pd.read_sql(f"SELECT * FROM {tabla}", conexion)
    df.to_csv(f"{tabla}.csv", index = False)
    print(f"{tabla}.csv exportado")
conexion.close()

