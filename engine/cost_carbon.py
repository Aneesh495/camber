"""
Camber Multi-Region Grid Carbon Intensity and Cloud Economics Model.
Calculates regional grid carbon emissions (gCO2e/kWh), operational expenditure (OPEX),
and sustainability metrics across continental Azure zones.
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple


# Average regional electrical grid carbon intensity factors (grams of CO2 equivalent per kWh)
# Based on real-world grid emission factors (Electricity Maps / WattTime data baselines)
REGIONAL_GRID_CARBON_INTENSITY: Dict[str, float] = {
    "switzerlandnorth": 28.0,      # Hydroelectric and nuclear base
    "switzerlandwest": 28.0,
    "francecentral": 55.0,         # High nuclear share
    "swedencentral": 42.0,         # Hydro and wind
    "northeurope": 315.0,          # Ireland mixed gas and wind
    "westeurope": 375.0,           # Netherlands gas and offshore wind
    "germanywestcentral": 380.0,   # Germany mixed renewables and coal/gas
    "eastus": 410.0,               # PJM Virginia grid
    "eastus2": 415.0,
    "centralus": 445.0,            # MISO Iowa wind and gas
    "westus2": 190.0,              # Pacific Northwest hydro
    "southeastasia": 460.0,        # Singapore natural gas
    "australiaeast": 520.0,        # NEM Australia coal and solar
}

# Standard Power Usage Effectiveness (PUE) for modern hyperscale datacenters
AZURE_DATACENTER_PUE = 1.18

# Estimated average server power consumption in Watts per SKU
SKU_POWER_WATTS: Dict[str, float] = {
    "Standard_DC2as_v5": 90.0,
    "Standard_DC4as_v5": 160.0,
    "Standard_DC8as_v5": 310.0,
    "Standard_D4ds_v5": 140.0,
    "Standard_D8ds_v5": 280.0,
    "Standard_B1": 60.0,
}

# Baseline hourly pricing in USD for Azure services
SERVICE_HOURLY_COST_USD: Dict[str, float] = {
    "Standard_DC2as_v5": 0.174,
    "Standard_DC4as_v5": 0.348,
    "Standard_DC8as_v5": 0.696,
    "Standard_D4ds_v5": 0.192,
    "Standard_D8ds_v5": 0.384,
    "ManagedHSM_B1": 3.20,
    "AzureFirewall_Premium": 1.75,
    "ApplicationGateway_WAF_v2": 0.36,
    "Postgres_D4ds_v5_HA": 0.58,
    "CosmosDB_4000_RU": 0.32,
    "LogAnalytics_PerGB": 0.08,
}


@dataclass
class ResourceEconomicProfile:
    resource_id: str
    name: str
    resource_type: str
    location: str
    hourly_cost_usd: float
    monthly_cost_usd: float
    power_watts: float
    monthly_energy_kwh: float
    monthly_carbon_kg_co2e: float


@dataclass
class ArchitectureSustainabilityReport:
    total_monthly_cost_usd: float
    total_monthly_energy_kwh: float
    total_monthly_carbon_kg_co2e: float
    regional_breakdown: Dict[str, Dict[str, float]] = field(default_factory=dict)
    resource_profiles: List[ResourceEconomicProfile] = field(default_factory=list)
    green_recommendations: List[str] = field(default_factory=list)


class CloudEconomicsEngine:
    """Calculates multi-region infrastructure costs and carbon footprint."""

    HOURS_PER_MONTH = 730.0

    def __init__(self, pue: float = AZURE_DATACENTER_PUE):
        self.pue = pue

    def evaluate_resource(
        self,
        resource_id: str,
        name: str,
        resource_type: str,
        location: str,
        sku_or_tier: str = "Standard_DC4as_v5",
        quantity: int = 1,
    ) -> ResourceEconomicProfile:
        """Calculate monthly cost, energy consumption, and carbon emission for a resource."""
        clean_loc = location.lower().replace(" ", "")
        grid_factor = REGIONAL_GRID_CARBON_INTENSITY.get(clean_loc, 400.0)

        hourly_rate = SERVICE_HOURLY_COST_USD.get(sku_or_tier, 0.25) * quantity
        monthly_cost = round(hourly_rate * self.HOURS_PER_MONTH, 2)

        power_watts = SKU_POWER_WATTS.get(sku_or_tier, 100.0) * quantity
        monthly_kwh = round((power_watts * self.pue * self.HOURS_PER_MONTH) / 1000.0, 2)

        monthly_carbon_kg = round((monthly_kwh * grid_factor) / 1000.0, 2)

        return ResourceEconomicProfile(
            resource_id=resource_id,
            name=name,
            resource_type=resource_type,
            location=clean_loc,
            hourly_cost_usd=round(hourly_rate, 4),
            monthly_cost_usd=monthly_cost,
            power_watts=power_watts,
            monthly_energy_kwh=monthly_kwh,
            monthly_carbon_kg_co2e=monthly_carbon_kg,
        )

    def generate_report(self, profiles: List[ResourceEconomicProfile]) -> ArchitectureSustainabilityReport:
        """Aggregate resource profiles into an architecture-wide cost and carbon report."""
        total_cost = sum(p.monthly_cost_usd for p in profiles)
        total_energy = sum(p.monthly_energy_kwh for p in profiles)
        total_carbon = sum(p.monthly_carbon_kg_co2e for p in profiles)

        regional_breakdown: Dict[str, Dict[str, float]] = {}
        for p in profiles:
            if p.location not in regional_breakdown:
                regional_breakdown[p.location] = {"cost_usd": 0.0, "carbon_kg": 0.0, "energy_kwh": 0.0}
            regional_breakdown[p.location]["cost_usd"] += p.monthly_cost_usd
            regional_breakdown[p.location]["carbon_kg"] += p.monthly_carbon_kg_co2e
            regional_breakdown[p.location]["energy_kwh"] += p.monthly_energy_kwh

        for loc in regional_breakdown:
            regional_breakdown[loc]["cost_usd"] = round(regional_breakdown[loc]["cost_usd"], 2)
            regional_breakdown[loc]["carbon_kg"] = round(regional_breakdown[loc]["carbon_kg"], 2)
            regional_breakdown[loc]["energy_kwh"] = round(regional_breakdown[loc]["energy_kwh"], 2)

        recommendations = []
        high_carbon_regions = [loc for loc, data in regional_breakdown.items() if REGIONAL_GRID_CARBON_INTENSITY.get(loc, 0.0) > 350.0]
        if high_carbon_regions:
            recommendations.append(
                f"Workloads in high carbon intensity grids ({', '.join(high_carbon_regions)}) can reduce emissions up to 90% by shifting non-latency-sensitive batch workloads to switzerlandnorth (28 gCO2e/kWh) or swedencentral (42 gCO2e/kWh)."
            )

        return ArchitectureSustainabilityReport(
            total_monthly_cost_usd=round(total_cost, 2),
            total_monthly_energy_kwh=round(total_energy, 2),
            total_monthly_carbon_kg_co2e=round(total_carbon, 2),
            regional_breakdown=regional_breakdown,
            resource_profiles=profiles,
            green_recommendations=recommendations,
        )
