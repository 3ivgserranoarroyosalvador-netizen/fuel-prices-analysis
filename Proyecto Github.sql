CREATE TABLE asia_fuel_prices (
    country                  VARCHAR(100),
    sub_region               VARCHAR(100),
    iso3                     CHAR(3),
    gasoline_usd_per_liter   DECIMAL(6,3),
    diesel_usd_per_liter     DECIMAL(6,3),
    lpg_usd_per_kg           DECIMAL(6,3),
    avg_monthly_income_usd   DECIMAL(10,2),
    fuel_affordability_index DECIMAL(8,2),
    oil_import_dependency_pct DECIMAL(6,2),
    refinery_capacity_kbpd   DECIMAL(10,2),
    ev_adoption_pct          DECIMAL(6,2),
    fuel_subsidy_active      VARCHAR(10),
    subsidy_cost_bn_usd      DECIMAL(8,2),
    co2_transport_mt         DECIMAL(10,2),
    price_date               VARCHAR(20),
    gasoline_pct_daily_wage  DECIMAL(6,2)
);
CREATE TABLE asia_subsidy_tracker (
    country                    VARCHAR(100),
    iso3                       CHAR(3),
    gasoline_subsidized        VARCHAR(10),
    diesel_subsidized          VARCHAR(10),
    subsidy_type               VARCHAR(50),
    annual_subsidy_cost_bn_usd DECIMAL(8,2),
    subsidy_pct_gdp            DECIMAL(6,2),
    subsidy_description        VARCHAR(500),
    last_price_change          VARCHAR(20),
    pricing_mechanism          VARCHAR(200),
    regulator                  VARCHAR(100)
);
CREATE TABLE price_trend_monthly (
    date                    VARCHAR(20),
    year                    INT,
    month                   INT,
    country                 VARCHAR(100),
    region                  VARCHAR(100),
    gasoline_usd_per_liter  DECIMAL(6,3),
    brent_crude_usd_bbl     DECIMAL(8,2),
    mom_change_pct          DECIMAL(8,2),
    yoy_change_pct          DECIMAL(8,2)
);

CREATE TABLE global_fuel_prices (
    country                 VARCHAR(100),
    region                  VARCHAR(100),
    iso3                    CHAR(3),
    gasoline_usd_per_liter  DECIMAL(6,3),
    diesel_usd_per_liter    DECIMAL(6,3),
    local_currency          VARCHAR(10),
    gasoline_local_price    DECIMAL(10,2),
    diesel_local_price      DECIMAL(10,2),
    price_date              VARCHAR(20),
    is_asian                INT,
    avg_fuel_usd            DECIMAL(6,3)
);

CREATE TABLE fuel_tax_comparison (
    country                  VARCHAR(100),
    region                   VARCHAR(100),
    gasoline_tax_pct         DECIMAL(6,2),
    diesel_tax_pct           DECIMAL(6,2),
    vat_pct                  DECIMAL(6,2),
    excise_usd_per_liter     DECIMAL(6,3),
    carbon_tax_active        VARCHAR(10),
    total_tax_usd_per_liter  DECIMAL(6,3),
    tax_burden_category      VARCHAR(20)
);

CREATE TABLE crude_oil_annual (
    year                  INT,
    brent_avg_usd_bbl     DECIMAL(8,2),
    wti_avg_usd_bbl       DECIMAL(8,2),
    brent_yoy_change_pct  DECIMAL(8,2),
    wti_yoy_change_pct    DECIMAL(8,2),
    key_event             VARCHAR(200),
    brent_wti_spread      DECIMAL(8,2),
    avg_price_usd_bbl     DECIMAL(8,2)
);

-- ============================================================
-- PORTAFOLIO SQL — World vs Asia Fuel Prices
-- Autor: Salvador | Ingeniería Industrial, UPIICSA-IPN
-- Dataset: 6 tablas relacionadas sobre precios de combustible
-- Herramienta: MySQL
-- ============================================================
-- TABLAS DISPONIBLES:
--   asia_fuel_prices      → snapshot de 22 países asiáticos
--   price_trend_monthly   → serie de tiempo mensual desde 2015
--   global_fuel_prices    → precios globales con moneda local
--   fuel_tax_comparison   → impuestos y carga fiscal por país
--   crude_oil_annual      → precio del crudo por año (Brent/WTI)
--   asia_subsidy_tracker  → detalle de subsidios por país
-- ============================================================
 
-- ==========================================
-- Parte 1: SELECT + WHERE + ORDER BY
-- ==========================================
-- Query 1: Top 5 países con la gasolina más cara en Asia
-- Pregunta: ¿Qué países tienen el mayor costo de gasolina?

select 
afp.country,
afp.sub_region,
afp.gasoline_usd_per_liter 
from asia_fuel_prices afp 
order by gasoline_usd_per_liter desc
limit 5;

-- Query 2: Países sin subsidio con ingreso mensual alto
-- Pregunta: ¿Qué economías fuertes no necesitan subsidiar el combustible? Ingreso alto > 2000

select
afp.country,
afp.fuel_subsidy_active,
afp.avg_monthly_income_usd,
afp.co2_transport_mt 
from asia_fuel_prices afp 
where afp.fuel_subsidy_active = "False"
	and afp.avg_monthly_income_usd > 2000
order by afp.avg_monthly_income_usd;

-- Se considero como ingreso alto > 2000 debido a que solo hay dos paises que superan este número


-- ==========================================
-- Parte 2: Group by + Funciones agregadas
-- ==========================================
-- Query 3: Precio promedio de combustible por sub-región
-- Pregunta: ¿Qué región de Asia paga más por el combustible en promedio?

select 
afp.sub_region,
COUNT(country) as Total_de_paises,
round(avg (afp.gasoline_pct_daily_wage), 2)as Promedio_gasolina,
round(avg (afp.diesel_usd_per_liter), 2) as Promedio_diesel,
round(avg (afp.lpg_usd_per_kg), 2)as Promedio_kg
from asia_fuel_prices afp 
group by sub_region
order by promedio_gasolina desc;

-- Se toma el promedio de la gasolina, diesel y el costo por kilogramos pero el que le da orden a la consulta 
-- es la gasolina debido a que es el combustible más común


-- Query 4: Costo total de subsidios y emisiones CO2 por región
-- Pregunta: ¿Cuánto gasta cada región en subsidios y cuánto contamina?

select 
afp.sub_region,
COUNT(case 
	when afp.fuel_subsidy_active = "True"
	then 1 end) as Paises_con_subsidio,
	SUM(afp.subsidy_cost_bn_usd) as Costo_total_bn_usd,
	SUM(afp.co2_transport_mt) as Co2_total
from asia_fuel_prices afp 
group by sub_region
order by costo_total_bn_usd desc;

-- Se toma como "1" debido a que el valor es verdadero queremos que nos lo de en una cantidad cuantitativa
-- Elijiéndose el "count" debido a que este ignora los valores "null", siendo en este caso "False" o "0"

-- ======================================================================
-- Parte 3: CASE WHEN
-- ======================================================================
-- Query 5: Clasificar países por nivel de asequibilidad del combustible
-- Pregunta: ¿Cuántos países tienen el combustible realmente accesible? 
-- Considerar Alta >= 50, Media >= 15, Baja >=5

select 
afp.country,
afp.sub_region,
afp.fuel_affordability_index,
afp.avg_monthly_income_usd,
case
	when afp.fuel_affordability_index >= 50 then "Alta - Accesible"
	when afp.fuel_affordability_index >= 15 then "Media - Moderada"
	when afp.fuel_affordability_index >= 5 then "Baja - Limitada"
	else "Muy baja - Insostenible"
end as nivel_asequibilidad
from asia_fuel_prices afp 
order by afp.fuel_affordability_index desc;


-- =======================================================================
-- Parte 4: Subconsultas
-- =======================================================================
-- Query 6: Paises con precio de gasolina por encima del promedio asiático
-- Pregunta: ¿Qué países pagan más que el promedio regional?

SELECT
    afp.country,
    afp.sub_region,
    afp.gasoline_usd_per_liter,
    ROUND(afp.gasoline_usd_per_liter - (SELECT AVG(gasoline_usd_per_liter)
        FROM asia_fuel_prices), 2) AS diferencia_vs_promedio
FROM asia_fuel_prices afp
WHERE afp.gasoline_usd_per_liter > (SELECT AVG(gasoline_usd_per_liter) FROM asia_fuel_prices)
ORDER BY afp.gasoline_usd_per_liter DESC;

-- Quert 7: País con mayor adopción de EVs dentro de cada sub-región
-- Pregunta: ¿Quién lidera la transición eléctrica en cada región?

select 
afp.country,
afp.sub_region,
afp.ev_adoption_pct
from asia_fuel_prices afp
where afp.ev_adoption_pct = (
	select MAX(afp.ev_adoption_pct)
	from asia_fuel_prices afp2
	where afp.sub_region = afp2.sub_region 
)
order by afp.ev_adoption_pct desc;

-- Al realizar este apartado es como hacer un join pero si poner un join

SELECT
    afp.country,
    afp.sub_region,
    afp.ev_adoption_pct
FROM asia_fuel_prices afp
INNER JOIN (
    SELECT sub_region, MAX(ev_adoption_pct) AS max_ev
    FROM asia_fuel_prices
    GROUP BY sub_region
) AS maximos ON afp.sub_region = maximos.sub_region
           AND afp.ev_adoption_pct = maximos.max_ev
ORDER BY afp.ev_adoption_pct DESC;

-- =======================================================================
-- Parte 5: CTEs (With)
-- =======================================================================
-- Query 8: Los países con subsidio emiten más CO2
-- Pregunta: ¿El subsidio al combustible se asocia con más emisiones?

with resumen_subsidios as(
	select 
		afp.fuel_subsidy_active,
		count(afp.country ) as Total_paises,
		round(avg(co2_transport_mt), 2)as Promedio_co2,
		round(avg(gasoline_usd_per_liter), 2)as Precio_promedio,
		round(avg(ev_adoption_pct), 2)as Adopcion_ev_promedio
	from asia_fuel_prices afp
	group by afp.fuel_subsidy_active 
)
select
	case when fuel_subsidy_active = "True" then "Con subsidio"
	else "Sin subsidio" end as tipo,
	total_paises,
	promedio_co2,
	precio_promedio,
	adopcion_ev_promedio 
from resumen_subsidios;

-- Query 9: El promedio del subsidio del diesel clasificadolo por la region y que sea mayor a 1
-- Pregunta:¿Cuál es el promedio del subsidio de diesel de cada región?

with promedio_subsidios as (
	select 
	afp.sub_region, 
	avg(afp.diesel_usd_per_liter) as promedio_diesel
	from asia_fuel_prices afp 
	group by afp.sub_region 
)
select 
sub_region,
promedio_diesel 
from promedio_subsidios 
where promedio_diesel > 1;

-- =======================================================================
-- Parte 6: JOIN
-- =======================================================================
-- Query 10: Precio real de gasolina vs carga fiscal por país
-- Tablas: asia_fuel_prices + fuel_tax_comparison
-- Pregunta: ¿Qué parte del precio que paga el consumidor son impuestos?

select 
afp.country,
afp.sub_region,
afp.gasoline_usd_per_liter as Precio_total,
ftc.total_tax_usd_per_liter as impuestos,
afp.gasoline_usd_per_liter - ftc.total_tax_usd_per_liter as Precio_sin_impuestos,
ftc.gasoline_tax_pct,
ftc.tax_burden_category,
ftc.carbon_tax_active 
from asia_fuel_prices afp 
join fuel_tax_comparison ftc on afp.country = ftc.country 
order by ftc.total_tax_usd_per_liter; 

-- Query 12: Perfil completo de subsidios por país
-- Tablas: asia_fuel_prices + asia_subsidy_tracker
-- Pregunta: ¿Qué mecanismo usa cada país para subsidiar el combustible?

select 
afp.country,
afp.sub_region,
afp.gasoline_usd_per_liter,
afp.avg_monthly_income_usd,
ast.annual_subsidy_cost_bn_usd,
ast.subsidy_pct_gdp,
ast.pricing_mechanism,
ast.regulator 
from asia_fuel_prices afp 
join asia_subsidy_tracker ast on afp.iso3 = ast.iso3
where afp.fuel_subsidy_active = "True"
order by ast.annual_subsidy_cost_bn_usd desc;

-- Query 13: Precio local de gasolina vs precio del crudo año a año
-- Tablas: price_trend_monthly + crude_oil_annual
-- Pregunta: ¿Cómo impacta el precio del crudo en los precios locales?

select 
ptm.year,
ptm.country,
ptm.region, 
round(avg(ptm.gasoline_usd_per_liter), 2)as Precio_local_promedio,
coa.brent_avg_usd_bbl as Brent_anual,
round(avg(ptm.yoy_change_pct), 2)as Cambio_yoy_pct
from price_trend_monthly ptm 
join crude_oil_annual coa on ptm.`year`= coa.`year`
where ptm.country in("India","China","Japon","Malaysia","Indonesia")
group by ptm.`year`, ptm.country , coa.brent_avg_usd_bbl, coa.key_event 
order by country, year; 

-- Query 14: Comparativa global — países asiáticos vs resto del mundo
-- Tablas: global_fuel_prices + fuel_tax_comparison
-- Pregunta: ¿Pagan más impuestos los países asiáticos que el resto del mundo?

select
gfp.region,
gfp.is_asian,
count(gfp.country) as Total_paises,
round(avg(gfp.gasoline_usd_per_liter), 2)as Precio_gasolina_promedio,
round(avg(ftc.gasoline_tax_pct), 2) as Impuesto_promedio_pct,
round(avg(ftc.total_tax_usd_per_liter),2) as Carga_fiscal_promedio
from global_fuel_prices gfp 
left join fuel_tax_comparison ftc  on gfp.country = ftc.country
group by gfp.region, gfp.is_asian
order by gfp.is_asian desc, precio_gasolina_promedio desc;

-- El "1" significa que pertences a Asia y el "0" que no pertenecen a Asia.
 
-- =======================================================================
-- Parte 7: CTEs (With) + JOIN
-- =======================================================================
-- Query 15: El promedio de gasolina al igual que el promedio impuestos totales por region
-- Pregunta:¿Cuál es el promedio de la gasolina y de los impuestos de cada región?

with promedio_combustible as(
	select
	afp.sub_region,
	round(avg(ftc.total_tax_usd_per_liter), 2) as promedio_total,
	round(avg(afp.gasoline_usd_per_liter),2) as promedio_gasolina
	from fuel_prices_portafolio.asia_fuel_prices afp 
	join fuel_prices_portafolio.fuel_tax_comparison ftc on afp.country = ftc.country
	group by sub_region
)
select 
sub_region,
promedio_gasolina,
promedio_total 
from promedio_combustible
order by promedio_total desc;

