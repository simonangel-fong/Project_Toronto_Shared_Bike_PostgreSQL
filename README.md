# Data Warehouse Project - Toronto Shared Bike (PostgreSQL Solution)

A data warehouse project of Toronto Shared Bike using PostgreSQL database.

- [Data Warehouse Project - Toronto Shared Bike (PostgreSQL Solution)](#data-warehouse-project---toronto-shared-bike-postgresql-solution)
  - [Data Warehouse](#data-warehouse)
    - [Logical Design](#logical-design)
    - [Physical Implementation](#physical-implementation)
    - [Connect with pgAdmin](#connect-with-pgadmin)
  - [ETL Pipeline](#etl-pipeline)
    - [Confirm](#confirm)
    - [Export Processed Data](#export-processed-data)
  - [Execute Pipeline](#execute-pipeline)

---

## Data Warehouse

- Data Source:
  - https://open.toronto.ca/dataset/bike-share-toronto-ridership-data/

### Logical Design

![pic](./pic/Logical_design_ERD.png)

---

### Physical Implementation

- Initialize PostgreSQL Instance

```sh
cd pgsql
docker compose up -d
```

---

### Connect with pgAdmin

- Connection

![pic](./pic/connect_pgadmin01.png)

- Tables & views

![pic](./pic/connect_pgadmin02.png)

---

## ETL Pipeline

- Diagram

![pic](./pic/etl.gif)

- Extract

```sh
docker exec -it postgresql bash /scripts/etl/extract.sh
```

![pic](./pic/etl01.png)

- Transform

```sh
docker exec -it postgresql bash /scripts/etl/transform.sh
```

![pic](./pic/etl02.png)

- Load

```sh
docker exec -it postgresql bash /scripts/etl/load.sh
```

![pic](./pic/etl03.png)

- Refresh Materalized View

```sh
docker exec -it postgresql bash /scripts/mv/mv_refresh.sh
```

![pic](./pic/mv01.png)

---

### Confirm

- Time dimension - hour

```sh
SELECT
	dim_year
	, dim_hour
	, dim_user
	, trip_count
	, duration_sum
FROM toronto_shared_bike.dw_schema.mv_user_year_hour_trip
ORDER BY
    dim_year
    , dim_hour
    , dim_user
;
```

![pic](./pic/query01.png)

- Time dimension - month


```sh
SELECT
	dim_year
	, dim_month
	, dim_user
	, trip_count
	, duration_sum
FROM toronto_shared_bike.dw_schema.mv_user_year_month_trip
ORDER BY
    dim_year
    , dim_month
    , dim_user
;
```

![pic](./pic/query02.png)

- Station dimension

```sh
SELECT
	dim_year
	, dim_user
	, dim_station
	, trip_count
FROM toronto_shared_bike.dw_schema.mv_user_year_station
ORDER BY
    dim_year
    , dim_user
    , trip_count DESC
;
```

![pic](./pic/query03.png)

---

### Export Processed Data

```sh
docker exec -it postgresql bash /scripts/export/export.sh
```

![pic](./pic/export01.png)

---

## Execute Pipeline


```sh
docker exec -it postgresql bash /scripts/pipeline/pipeline.sh
```