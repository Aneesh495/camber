# Carbon Footprint & Cloud Economics Specification

## 1. Electrical Grid Carbon Intensity Model

Modern cloud engineering requires accounting for the environmental cost of computational workloads. Regional electrical grids possess vastly different generation mixes: hydro and nuclear grids emit negligible carbon, while coal and gas grids emit hundreds of grams of carbon per kilowatt-hour.

Camber models carbon emissions using regional grid emission factors ($gCO_2e/kWh$):

| Azure Region | Primary Grid | Grid Factor ($gCO_2e/kWh$) | Generation Characteristics |
|---|---|---|---|
| `switzerlandnorth` | Swiss National Grid | 28.0 | Baseload hydroelectric and nuclear |
| `swedencentral` | Nordic Power Pool | 42.0 | Hydroelectric and onshore wind |
| `francecentral` | French Transmission Grid | 55.0 | High nuclear baseload |
| `westus2` | Pacific Northwest Grid | 190.0 | Columbia River hydroelectric |
| `northeurope` | EirGrid (Ireland) | 315.0 | Mixed natural gas and offshore wind |
| `westeurope` | TenneT (Netherlands) | 375.0 | Natural gas and offshore wind |
| `germanywestcentral` | German Federal Grid | 380.0 | Wind, solar, natural gas, lignite |
| `eastus` | PJM Interconnection (Virginia) | 410.0 | Natural gas, coal, nuclear |
| `centralus` | MISO (Iowa) | 445.0 | Wind and coal/gas |
| `southeastasia` | Singapore National Grid | 460.0 | Natural gas imports |

---

## 2. Energy and Carbon Computation Formula

For any resource running in region $r$ over a monthly period of $H = 730$ hours:

$$E_{\text{monthly}} = \frac{P_{\text{watts}} \cdot \text{PUE} \cdot H}{1000} \quad [\text{kWh}]$$

$$\text{Carbon}_{\text{monthly}} = \frac{E_{\text{monthly}} \cdot I_{\text{grid}}(r)}{1000} \quad [\text{kg } CO_2e]$$

Where:
- $P_{\text{watts}}$ is the thermal design power draw of the provisioned SKU
- $\text{PUE} = 1.18$ is the hyperscale datacenter Power Usage Effectiveness
- $I_{\text{grid}}(r)$ is the carbon intensity of region $r$

Workloads deployed to `switzerlandnorth` achieve an immediate 93.2% reduction in greenhouse gas emissions compared to the same workload operating in `eastus`.
