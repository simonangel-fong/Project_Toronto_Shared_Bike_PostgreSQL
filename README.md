# Data Warehouse Project - Toronto Shared Bike (PostgreSQL Solution)

A data warehouse project of Toronto Shared Bike using PostgreSQL database.

- [Data Warehouse Project - Toronto Shared Bike (PostgreSQL Solution)](#data-warehouse-project---toronto-shared-bike-postgresql-solution)
    - [Physical Implementation](#physical-implementation)

---

### Physical Implementation

- Initialize MSSQL Instance

```sh
cd pgsql
docker compose up -d
```

- Extract

```sh
docker exec -it postgresql bash /var/lib/postgresql/scripts/etl/extract.sh
```

- Transform

```sh
docker exec -it postgresql bash /var/lib/postgresql/scripts/etl/transform.sh
```

- Load

```sh
docker exec -it postgresql bash /var/lib/postgresql/scripts/etl/load.sh
```

- Refresh Materalized View

```sh
docker exec -it postgresql bash /var/lib/postgresql/scripts/mv/mv_refresh.sh
```

- Export

```sh
docker exec -it postgresql bash /var/lib/postgresql/scripts/export/export.sh
```

---

- Pipeline

```sh
docker exec -it postgresql bash /var/lib/postgresql/scripts/etl/extract.sh & docker exec -it postgresql bash /var/lib/postgresql/scripts/etl/transform.sh & docker exec -it postgresql bash /var/lib/postgresql/scripts/etl/load.sh & docker exec -it postgresql bash /var/lib/postgresql/scripts/mv/mv_refresh.sh & docker exec -it postgresql bash /var/lib/postgresql/scripts/export/export.sh
```
