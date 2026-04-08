#!/usr/bin/env python3
"""
Balance simulation runner for VENTURE.

Runs a simplified but faithful simulation of the game economy across
the 12-cell playtest matrix (4 company types x 3 difficulties) with
multiple AI strategies per cell.

Usage:
    python3 tools/balance_sim.py              # run all 12 cells
    python3 tools/balance_sim.py --type saas  # one company type
    python3 tools/balance_sim.py --diff normal --type consumer
"""

import argparse
import json
import math
import random
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

REPO = Path(__file__).resolve().parent.parent
FEATURES_PATH = REPO / "src" / "data" / "features.json"

# ─── Constants from the game ────────────────────────────────────────────────

DIFFICULTY_MULTS = {
    "sandbox": {"cash_mult": 2.0, "churn_mult": 0.5, "competitor_mult": 0.5,
                "fundraise_amount_mult": 1.12, "fundraise_threshold_shift": -0.05,
                "event_pressure_mult": 0.85},
    "normal":  {"cash_mult": 1.0, "churn_mult": 1.0, "competitor_mult": 1.0,
                "fundraise_amount_mult": 1.0, "fundraise_threshold_shift": 0.0,
                "event_pressure_mult": 1.0},
    "hardcore": {"cash_mult": 0.75, "churn_mult": 1.5, "competitor_mult": 1.5,
                 "fundraise_amount_mult": 0.90, "fundraise_threshold_shift": 0.06,
                 "event_pressure_mult": 1.20},
}

# Starting conditions by scenario
SCENARIOS = {
    "garage":       {"cash": 60_000, "office": 0, "reputation": 30, "has_funding": False},
    "accelerator":  {"cash": 150_000, "office": 0, "reputation": 30, "has_funding": False},
    "vc_backed":    {"cash": 2_000_000, "office": 1, "reputation": 30, "has_funding": True},
}
DEFAULT_SCENARIO = "accelerator"

OFFICE_COSTS = [0.0, 1_000.0, 4_000.0, 10_000.0]

# Salary ranges per quarter by seniority index (junior=0 .. principal=4)
SALARY_RANGES = [
    (9_000, 16_000),
    (20_000, 32_000),
    (32_000, 52_000),
    (48_000, 72_000),
    (68_000, 98_000),
]

# Revenue constants by type
REVENUE_PARAMS = {
    "saas":        {"model": "saas",        "conversion": 0.06, "arpu_monthly": 28.0},
    "consumer":    {"model": "consumer",    "ad_cpm": 0.06, "premium_pct": 0.06, "premium_price": 8.0},
    "marketplace": {"model": "marketplace", "gmv_per_user": 65.0, "take_rate": 0.10},
    "dev_tools":   {"model": "dev_tools",   "calls_per_user": 1200, "price_per_call": 0.0012},
}

GROWTH_BALANCE = {
    "saas":        {"maturity_start": 35000, "maturity_full": 480000, "maturity_target": 0.70, "organic_base_mult": 0.7, "feature3_bonus": 1.4},
    "consumer":    {"maturity_start": 22000, "maturity_full": 420000, "maturity_target": 0.60, "organic_base_mult": 1.3, "base_new_mult": 1.6},
    "marketplace": {"maturity_start": 30000, "maturity_full": 500000, "maturity_target": 0.64, "cold_start_threshold": 500, "cold_start_penalty": 0.4, "hot_mult": 1.5},
    "dev_tools":   {"maturity_start": 26000, "maturity_full": 380000, "maturity_target": 0.67, "organic_base_mult": 0.6, "rep_bonus_mult": 1.8},
}

SUSTAINABLE_WIN = {
    "saas":        {"users": 10_000, "features": 8, "revenue": 70_000},
    "consumer":    {"users": 8_000,  "features": 7, "revenue": 40_000},
    "marketplace": {"users": 14_000, "features": 8, "revenue": 260_000},
    "dev_tools":   {"users": 12_000, "features": 8, "revenue": 60_000},
}

BASE_ORGANIC_USERS_PER_QUARTER = 35
MARKETING_USER_MULT = 0.5
FEATURE_COST_BASE = 100.0
MAX_QUARTERS = 40

# ─── Data classes ────────────────────────────────────────────────────────────

@dataclass
class Employee:
    seniority: int = 1    # 0=junior, 1=mid, 2=senior
    skill: int = 50
    speed: int = 50
    morale: int = 70
    salary: float = 24_000.0
    assignment: str = "features"  # features, bugs, debt, infra

    def work_output(self) -> float:
        base = (min(100, max(0, self.skill)) * min(100, max(0, self.speed))) / 100.0
        morale_mult = 0.5 + 0.7 * (min(100, max(0, self.morale)) / 100.0)
        return base * morale_mult


@dataclass
class Product:
    features: list = field(default_factory=list)
    tech_debt: int = 0
    bugs: int = 0
    stability: int = 80
    ux_score: int = 50
    users: int = 0
    dau: int = 0
    churn_rate: float = 0.05
    revenue_mult: float = 1.0
    feature_progress: float = 0.0
    target_feature_idx: int = 0
    user_growth_flat_bonus: int = 0
    dau_bonus: float = 0.0

    def feature_count(self) -> int:
        return len(self.features)

    def avg_quality(self) -> float:
        if not self.features:
            return 0.0
        return sum(f["quality"] for f in self.features) / len(self.features)

    def dev_speed_mult(self) -> float:
        if self.tech_debt > 75:
            return 0.5
        elif self.tech_debt > 50:
            return 0.75
        return 1.0

    def feature_cost_multiplier(self) -> float:
        shipped = len(self.features)
        if shipped <= 1:
            return 0.7
        elif shipped == 2:
            return 0.85
        elif shipped == 3:
            return 1.0
        else:
            return 1.0 * (1.26 ** (shipped - 3))


@dataclass
class Company:
    cash: float = 150_000.0
    type_key: str = "saas"
    reputation: int = 30
    office_level: int = 0
    founder_technical: int = 5
    founder_finance: int = 5
    founder_business: int = 5
    founder_people: int = 5
    has_funding: bool = False
    marketing_budget: float = 0.0
    angel_bailout_used: bool = False


@dataclass
class SimState:
    company: Company = field(default_factory=Company)
    product: Product = field(default_factory=Product)
    employees: list = field(default_factory=list)
    quarter: int = 1
    founder_energy: int = 80
    board_patience: int = 4
    revenue: float = 0.0
    burn_rate: float = 0.0
    consecutive_profitable: int = 0
    end_reason: str = ""
    cash_floor: float = float("inf")
    funding_history: list = field(default_factory=list)
    first_feature_q: int = 0
    first_revenue_q: int = 0
    difficulty: str = "normal"

    @property
    def diff(self) -> dict:
        return DIFFICULTY_MULTS[self.difficulty]


# ─── Feature catalog ────────────────────────────────────────────────────────

def load_features() -> dict:
    with open(FEATURES_PATH) as f:
        return json.load(f)


FEATURE_CATALOG = {}


def get_available_features(type_key: str, shipped_ids: set) -> list:
    catalog = FEATURE_CATALOG.get(type_key, [])
    result = []
    for f in catalog:
        fid = f["id"]
        if fid in shipped_ids:
            continue
        prereqs = f.get("prerequisites", [])
        if all(p in shipped_ids for p in prereqs):
            result.append(f)
    return result


# ─── Revenue calculation ────────────────────────────────────────────────────

def calculate_revenue(state: SimState) -> float:
    p = state.product
    params = REVENUE_PARAMS[state.company.type_key]
    model = params["model"]

    if model == "saas":
        paying = p.users * params["conversion"]
        return paying * params["arpu_monthly"] * 3.0 * p.revenue_mult

    elif model == "consumer":
        dau = max(1, int(p.users * 0.35))  # simplified DAU estimate
        ad_rev = dau * params["ad_cpm"] * 90
        premium = p.users * params["premium_pct"] * params["premium_price"] * 3
        return (ad_rev + premium) * p.revenue_mult

    elif model == "marketplace":
        return p.users * params["gmv_per_user"] * params["take_rate"] * 3.0 * p.revenue_mult

    elif model == "dev_tools":
        return p.users * params["calls_per_user"] * params["price_per_call"] * 3.0 * p.revenue_mult

    return 0.0


# ─── User growth ────────────────────────────────────────────────────────────

def calculate_user_growth(state: SimState) -> int:
    p = state.product
    c = state.company
    gb = GROWTH_BALANCE[c.type_key]

    quality_factor = p.avg_quality() / 100.0
    feature_pull = min(p.feature_count() * 0.5, 5.0)
    rep_bonus = c.reputation / 100.0
    ux_pull = 0.86 + (p.ux_score / 100.0) * 0.30
    stability_pull = 0.88 + (p.stability / 100.0) * 0.24
    biz_bonus = 1.0 + c.founder_business * 0.04

    base_new = BASE_ORGANIC_USERS_PER_QUARTER + math.ceil(feature_pull * 5)
    organic_rate = 0.01 + quality_factor * 0.04
    organic_rate *= ux_pull * stability_pull

    # Type-specific modifiers
    if c.type_key == "saas":
        organic_rate *= gb.get("organic_base_mult", 0.7)
        if p.feature_count() >= 3:
            organic_rate *= gb.get("feature3_bonus", 1.4)
    elif c.type_key == "consumer":
        base_new = math.ceil(base_new * gb.get("base_new_mult", 1.6))
        organic_rate *= gb.get("organic_base_mult", 1.3)
    elif c.type_key == "marketplace":
        if p.users < gb.get("cold_start_threshold", 500):
            organic_rate *= gb.get("cold_start_penalty", 0.4)
        else:
            organic_rate *= gb.get("hot_mult", 1.5)
    elif c.type_key == "dev_tools":
        organic_rate *= gb.get("organic_base_mult", 0.6)
        rep_bonus *= gb.get("rep_bonus_mult", 1.8)

    growth_from_existing = math.ceil(p.users * organic_rate * biz_bonus)
    reputation_pull = math.ceil(base_new * rep_bonus * biz_bonus)

    # Marketing spend → user acquisition
    marketing_new = 0
    if c.marketing_budget > 0:
        marketing_new = math.ceil(MARKETING_USER_MULT * math.sqrt(c.marketing_budget) * biz_bonus)

    feature_bonus = state.product.user_growth_flat_bonus
    total_new = max(0, base_new + growth_from_existing + reputation_pull + feature_bonus + marketing_new)

    # Maturity damping
    if p.users > gb["maturity_start"]:
        t = min(1.0, (p.users - gb["maturity_start"]) / max(1, gb["maturity_full"] - gb["maturity_start"]))
        maturity_mult = 1.0 - t * (1.0 - gb["maturity_target"])
        total_new = math.ceil(total_new * max(gb["maturity_target"], maturity_mult))

    # Churn
    churn_mult = state.diff.get("churn_mult", 1.0)
    churned = math.ceil(p.users * p.churn_rate * churn_mult)

    return total_new - churned


# ─── Fundraising ─────────────────────────────────────────────────────────────

ROUND_SEQUENCE = ["Seed", "Series A", "Series B", "Growth"]
ROUND_RANGES = {
    "Seed":     {"min": 250_000, "max": 2_000_000},
    "Series A": {"min": 2_000_000, "max": 15_000_000},
    "Series B": {"min": 10_000_000, "max": 50_000_000},
    "Growth":   {"min": 30_000_000, "max": 100_000_000},
}


def company_strength(state: SimState) -> float:
    user_score = min(1.0, state.product.users / 50_000)
    rev_score = min(1.0, state.revenue / 100_000)
    team_score = min(1.0, len(state.employees) / 15.0)
    rep_score = state.company.reputation / 100.0
    return min(1.0, user_score * 0.3 + rev_score * 0.3 + team_score * 0.2 + rep_score * 0.2)


def attempt_fundraise(state: SimState) -> Optional[float]:
    """Try to raise the next round. Returns amount raised or None."""
    if state.quarter < 3:
        return None

    rounds_raised = len(state.funding_history)
    if rounds_raised >= len(ROUND_SEQUENCE):
        return None

    round_name = ROUND_SEQUENCE[rounds_raised]
    rr = ROUND_RANGES[round_name]
    quality = company_strength(state)

    # Threshold check — scales with rounds raised.
    threshold = 0.08 + rounds_raised * 0.06
    threshold += state.diff.get("fundraise_threshold_shift", 0.0)
    if quality < threshold:
        return None

    amount_mult = state.diff.get("fundraise_amount_mult", 1.0)
    amount = rr["min"] + (rr["max"] - rr["min"]) * min(1.0, quality)
    amount *= amount_mult
    amount = round(amount / 10_000) * 10_000

    state.company.cash += amount
    state.company.has_funding = True
    state.funding_history.append({"round": round_name, "amount": amount, "quarter": state.quarter})
    return amount


# ─── Simulation steps ───────────────────────────────────────────────────────

def apply_work(state: SimState):
    shipped_ids = {f["id"] for f in state.product.features}
    available = get_available_features(state.company.type_key, shipped_ids)

    for emp in state.employees:
        output = emp.work_output() * state.product.dev_speed_mult()
        tech_bonus = state.company.founder_technical * 0.05

        if emp.assignment == "features":
            if not available:
                continue
            target = available[0]
            cost = target.get("cost", FEATURE_COST_BASE) * state.product.feature_cost_multiplier()
            state.product.feature_progress += output * 0.5
            if state.product.feature_progress >= cost:
                state.product.feature_progress -= cost
                quality = max(15, min(100,
                    math.ceil(output * 0.82) + random.randint(-8, 8) + round(tech_bonus * 5)
                    - round(state.product.tech_debt * 0.18)
                    - round(min(15, state.product.bugs * 0.35))
                ))
                state.product.features.append({"id": target["id"], "name": target["name"], "quality": quality})

                # Apply feature effects
                effects = target.get("effects", {})
                if "ux_bonus" in effects:
                    state.product.ux_score = min(100, state.product.ux_score + int(effects["ux_bonus"]))
                if "stability_bonus" in effects:
                    state.product.stability = min(100, state.product.stability + int(effects["stability_bonus"]))
                if "churn_reduction" in effects:
                    state.product.churn_rate = max(0.01, state.product.churn_rate - float(effects["churn_reduction"]))
                if "revenue_mult" in effects:
                    state.product.revenue_mult = min(5.0, state.product.revenue_mult * float(effects["revenue_mult"]))
                if "reputation_bonus" in effects:
                    state.company.reputation = min(100, state.company.reputation + int(effects["reputation_bonus"]))
                if "user_growth_bonus" in effects:
                    state.product.user_growth_flat_bonus += int(effects["user_growth_bonus"])
                if "dau_bonus" in effects:
                    state.product.dau_bonus += float(effects["dau_bonus"])

                if state.first_feature_q == 0:
                    state.first_feature_q = state.quarter
                shipped_ids.add(target["id"])
                available = get_available_features(state.company.type_key, shipped_ids)

        elif emp.assignment == "bugs":
            bug_mult = (1.0 + tech_bonus)
            state.product.bugs = max(0, state.product.bugs - max(1, math.ceil(output * 0.16 * bug_mult)))
            state.product.churn_rate = max(0.01, state.product.churn_rate - output * 0.00003 * bug_mult)

        elif emp.assignment == "debt":
            debt_work = output * 0.11
            state.product.tech_debt = max(0, state.product.tech_debt - max(1, math.ceil(debt_work)))
            state.product.stability = min(100, state.product.stability + max(0, math.ceil(debt_work * 0.15)))

        elif emp.assignment == "infra":
            infra_work = output * 0.09
            state.product.stability = min(100, state.product.stability + max(1, math.ceil(infra_work)))
            state.product.churn_rate = max(0.01, state.product.churn_rate - infra_work * 0.00002)


def update_product_metrics(state: SimState):
    p = state.product
    if p.tech_debt > 75:
        p.bugs += random.randint(2, 5)
    elif p.tech_debt > 50:
        p.bugs += random.randint(1, 3)

    if p.stability < 30:
        p.churn_rate += 0.02
    elif p.stability < 50:
        p.churn_rate += 0.005
    elif p.stability > 80:
        p.churn_rate = max(0.01, p.churn_rate - 0.005)

    if p.bugs > 20:
        p.churn_rate += 0.01
    if p.ux_score < 45:
        p.churn_rate += 0.004
    elif p.ux_score > 78:
        p.churn_rate = max(0.01, p.churn_rate - 0.0025)

    p.churn_rate = max(0.01, min(0.40, p.churn_rate))


def update_users(state: SimState):
    net = calculate_user_growth(state)
    state.product.users = max(0, state.product.users + net)
    dau_ratio = 0.30 + state.product.dau_bonus
    state.product.dau = max(0, int(state.product.users * max(0.05, min(0.7, dau_ratio))))


def update_cash(state: SimState):
    rev = calculate_revenue(state)
    state.revenue = rev
    if rev > 0 and state.first_revenue_q == 0:
        state.first_revenue_q = state.quarter

    salary_total = sum(e.salary for e in state.employees)
    finance_discount = 1.0 - state.company.founder_finance * 0.02
    infra_cost = max(10.0, state.product.users * 0.006) * max(0.6, finance_discount)
    office_cost = OFFICE_COSTS[min(state.company.office_level, len(OFFICE_COSTS) - 1)]

    marketing_cost = state.company.marketing_budget
    state.burn_rate = salary_total + infra_cost + office_cost + marketing_cost
    net = rev - state.burn_rate
    state.company.cash += net
    state.cash_floor = min(state.cash_floor, state.company.cash)

    if net > 0:
        state.consecutive_profitable += 1
    else:
        state.consecutive_profitable = 0


def update_founder_energy(state: SimState):
    delta = 0
    if state.burn_rate > 0:
        runway = state.company.cash / state.burn_rate
        if runway < 2.0:
            delta -= 8
        elif runway < 4.0:
            delta -= 3

    if not state.employees and state.quarter > 1:
        delta -= 5

    if state.revenue > state.burn_rate:
        delta += 6

    avg_morale = sum(e.morale for e in state.employees) / max(1, len(state.employees))
    if avg_morale >= 70:
        delta += 3
    elif avg_morale < 40:
        delta -= 3

    if 0 < len(state.employees) <= 5 and avg_morale >= 60:
        delta += 2

    state.founder_energy = max(0, min(100, state.founder_energy + delta))


def update_board_patience(state: SimState):
    if not state.company.has_funding:
        return
    # Simplified: if users or revenue are growing, patience holds
    if state.product.users > 0 and state.revenue > 0:
        state.board_patience = min(6, state.board_patience + 1)
    else:
        state.board_patience -= 1


def update_morale(state: SimState):
    for emp in state.employees:
        # Simplified morale drift
        if state.revenue > state.burn_rate:
            emp.morale = min(100, emp.morale + random.randint(0, 3))
        elif state.company.cash < 50_000:
            emp.morale = max(0, emp.morale - random.randint(1, 5))
        else:
            emp.morale = max(0, min(100, emp.morale + random.randint(-2, 2)))


def check_end(state: SimState) -> Optional[str]:
    if state.founder_energy <= 0:
        return "burnout"
    if state.company.has_funding and state.board_patience <= 0:
        return "board_takeover"
    if state.company.cash <= 0 and state.revenue < state.burn_rate:
        return "bankrupt"
    if state.product.users <= 0 and state.quarter > 12:
        return "dead_product"

    # Win conditions
    annualized = state.revenue * 4
    if annualized >= 100_000_000 and state.product.users >= 100_000:
        return "win_ipo"

    win_req = SUSTAINABLE_WIN[state.company.type_key]
    if (state.quarter >= 20
        and state.consecutive_profitable >= 6
        and state.product.users >= win_req["users"]
        and state.product.feature_count() >= win_req["features"]
        and state.revenue >= win_req["revenue"]):
        return "win_sustainable"

    return None


# ─── AI Strategy ─────────────────────────────────────────────────────────────

def downsize_if_needed(state: SimState, min_team: int = 1) -> None:
    """Fire employees when burn massively exceeds revenue and runway is short."""
    if not state.employees or len(state.employees) <= min_team:
        return
    if state.burn_rate <= 0 or state.revenue >= state.burn_rate * 0.5:
        return  # Revenue covers at least half of burn — OK
    runway = state.company.cash / state.burn_rate if state.burn_rate > 0 else 99
    if runway > 6:
        return  # Enough runway to keep going
    # Fire the most expensive employee
    state.employees.sort(key=lambda e: e.salary, reverse=True)
    state.employees.pop(0)


def hire_employee(state: SimState, seniority: int = 1) -> Employee:
    lo, hi = SALARY_RANGES[min(seniority, len(SALARY_RANGES) - 1)]
    salary = random.uniform(lo, hi)
    skill = random.randint(30, 70) + seniority * 10
    speed = random.randint(30, 70) + seniority * 5
    return Employee(seniority=seniority, skill=min(100, skill), speed=min(100, speed),
                    morale=random.randint(60, 80), salary=salary)


def balanced_strategy(state: SimState):
    """Balanced AI: hires when affordable, splits assignments sensibly."""
    team = state.employees

    # Angel bailout at Q3 if no funding
    if state.quarter >= 3 and not state.company.has_funding and not state.company.angel_bailout_used:
        state.company.cash += 50_000
        state.company.reputation = min(100, state.company.reputation + 5)
        state.company.angel_bailout_used = True

    # Try fundraising when runway < 4 quarters
    if state.burn_rate > 0:
        runway = state.company.cash / state.burn_rate
    else:
        runway = 99
    if runway < 4:
        attempt_fundraise(state)
        if state.burn_rate > 0:
            runway = state.company.cash / state.burn_rate

    # Downsize if burning way more than earning
    downsize_if_needed(state, min_team=2)
    team = state.employees  # refresh reference

    # Set marketing budget based on runway
    if runway > 6 and state.product.feature_count() >= 1:
        state.company.marketing_budget = 3_000.0
    elif runway > 4 and state.product.feature_count() >= 1:
        state.company.marketing_budget = 1_000.0
    else:
        state.company.marketing_budget = 0.0

    # Don't hire beyond what revenue can eventually support
    max_team = max(2, int(state.revenue / 8_000) + 3) if state.revenue > 0 else 3

    # Hiring: add engineers if runway > 4 quarters, cap by revenue
    while len(team) < 2 and state.quarter <= 2:
        team.append(hire_employee(state, 1))
    if runway > 5 and len(team) < min(8, max_team) and state.quarter % 2 == 0:
        team.append(hire_employee(state, min(2, state.quarter // 6)))

    # Office upgrade
    if len(team) >= 6 and state.company.office_level < 1 and state.company.cash > 100_000:
        state.company.office_level = 1
    if len(team) >= 10 and state.company.office_level < 2 and state.company.cash > 500_000:
        state.company.office_level = 2

    # Assignment split
    n = len(team)
    if n == 0:
        return
    features_count = max(1, n // 2)
    bugs_count = 1 if n >= 3 and state.product.bugs > 5 else 0
    debt_count = 1 if n >= 4 and state.product.tech_debt > 30 else 0
    infra_count = 1 if n >= 5 and state.product.stability < 60 else 0
    # Fill remaining with features
    assigned = features_count + bugs_count + debt_count + infra_count
    if assigned < n:
        features_count += n - assigned
    elif assigned > n:
        features_count = max(1, n - bugs_count - debt_count - infra_count)

    idx = 0
    for i in range(features_count):
        if idx < n:
            team[idx].assignment = "features"
            idx += 1
    for i in range(bugs_count):
        if idx < n:
            team[idx].assignment = "bugs"
            idx += 1
    for i in range(debt_count):
        if idx < n:
            team[idx].assignment = "debt"
            idx += 1
    for i in range(infra_count):
        if idx < n:
            team[idx].assignment = "infra"
            idx += 1


def aggressive_strategy(state: SimState):
    """Aggressive: hires fast, features-first."""
    team = state.employees

    # Angel bailout at Q3
    if state.quarter >= 3 and not state.company.has_funding and not state.company.angel_bailout_used:
        state.company.cash += 50_000
        state.company.reputation = min(100, state.company.reputation + 5)
        state.company.angel_bailout_used = True

    if state.burn_rate > 0:
        runway = state.company.cash / state.burn_rate
    else:
        runway = 99

    # Aggressively fundraise
    if runway < 6:
        attempt_fundraise(state)
        if state.burn_rate > 0:
            runway = state.company.cash / state.burn_rate

    # Downsize if burning way more than earning
    downsize_if_needed(state, min_team=2)
    team = state.employees

    # Aggressive marketing
    if state.product.feature_count() >= 1:
        state.company.marketing_budget = 6_000.0
    else:
        state.company.marketing_budget = 0.0

    max_team = max(3, int(state.revenue / 6_000) + 4) if state.revenue > 0 else 4
    while len(team) < 3 and state.quarter <= 2:
        team.append(hire_employee(state, 1))
    if runway > 3 and len(team) < min(10, max_team):
        team.append(hire_employee(state, min(2, state.quarter // 4)))

    if len(team) >= 6 and state.company.office_level < 1:
        state.company.office_level = 1
    if len(team) >= 10 and state.company.office_level < 2:
        state.company.office_level = 2

    n = len(team)
    for i, emp in enumerate(team):
        if i < n - 1:
            emp.assignment = "features"
        else:
            emp.assignment = "bugs" if state.product.bugs > 10 else "features"


def conservative_strategy(state: SimState):
    """Conservative: small team, balanced assignments."""
    team = state.employees

    # Angel bailout at Q3
    if state.quarter >= 3 and not state.company.has_funding and not state.company.angel_bailout_used:
        state.company.cash += 50_000
        state.company.reputation = min(100, state.company.reputation + 5)
        state.company.angel_bailout_used = True

    if state.burn_rate > 0:
        runway = state.company.cash / state.burn_rate
    else:
        runway = 99

    # Conservative fundraise only when desperate
    if runway < 2:
        attempt_fundraise(state)
        if state.burn_rate > 0:
            runway = state.company.cash / state.burn_rate

    # Downsize if burning way more than earning
    downsize_if_needed(state, min_team=1)
    team = state.employees

    # Conservative: no marketing until stable
    if runway > 8 and state.product.feature_count() >= 2:
        state.company.marketing_budget = 1_000.0
    else:
        state.company.marketing_budget = 0.0

    max_team = max(1, int(state.revenue / 10_000) + 2) if state.revenue > 0 else 2

    if len(team) < 1 and state.quarter <= 1:
        team.append(hire_employee(state, 1))
    if runway > 8 and len(team) < min(5, max_team) and state.quarter % 3 == 0:
        team.append(hire_employee(state, 1))

    n = len(team)
    if n >= 4:
        team[0].assignment = "features"
        team[1].assignment = "features"
        team[2].assignment = "bugs"
        team[3].assignment = "debt"
        for i in range(4, n):
            team[i].assignment = "features"
    elif n >= 2:
        team[0].assignment = "features"
        team[1].assignment = "bugs" if state.product.bugs > 5 else "features"
    elif n == 1:
        team[0].assignment = "features"


STRATEGIES = {
    "balanced": balanced_strategy,
    "aggressive": aggressive_strategy,
    "conservative": conservative_strategy,
}


# ─── Main simulation loop ───────────────────────────────────────────────────

def run_simulation(type_key: str, difficulty: str, strategy_name: str,
                   scenario: str = DEFAULT_SCENARIO,
                   seed: Optional[int] = None, verbose: bool = False) -> dict:
    if seed is not None:
        random.seed(seed)

    sc = SCENARIOS[scenario]
    state = SimState()
    state.difficulty = difficulty
    state.company.type_key = type_key
    state.company.cash = sc["cash"] * DIFFICULTY_MULTS[difficulty]["cash_mult"]
    state.company.reputation = sc["reputation"]
    state.company.office_level = sc["office"]
    state.company.has_funding = sc["has_funding"]
    if sc["has_funding"]:
        state.funding_history.append({"round": "Seed", "amount": sc["cash"], "quarter": 0})

    strategy_fn = STRATEGIES[strategy_name]

    for q in range(1, MAX_QUARTERS + 1):
        state.quarter = q

        # AI decides hiring/assignments
        strategy_fn(state)

        # Simulation steps
        apply_work(state)
        update_product_metrics(state)
        update_users(state)
        update_cash(state)
        update_founder_energy(state)
        update_board_patience(state)
        update_morale(state)

        # Feature auto-target: pick first available if none targeted
        shipped_ids = {f["id"] for f in state.product.features}
        available = get_available_features(type_key, shipped_ids)
        # (auto-targeting is implicit in apply_work)

        if verbose and q % 4 == 0:
            print(f"  Q{q:2d}: ${state.company.cash:>10,.0f}  users={state.product.users:>7,}  "
                  f"features={state.product.feature_count()}  rev=${state.revenue:>8,.0f}  "
                  f"burn=${state.burn_rate:>8,.0f}  energy={state.founder_energy}  "
                  f"team={len(state.employees)}")

        end = check_end(state)
        if end:
            state.end_reason = end
            break
    else:
        state.end_reason = "timeout"

    return {
        "type": type_key,
        "difficulty": difficulty,
        "strategy": strategy_name,
        "end_reason": state.end_reason,
        "quarter_reached": state.quarter,
        "features_shipped": state.product.feature_count(),
        "users": state.product.users,
        "cash": state.company.cash,
        "cash_floor": state.cash_floor if state.cash_floor != float("inf") else 0,
        "revenue_per_q": state.revenue,
        "team_size": len(state.employees),
        "founder_energy": state.founder_energy,
        "first_feature_q": state.first_feature_q,
        "first_revenue_q": state.first_revenue_q,
        "rounds_raised": len(state.funding_history),
        "total_raised": sum(r["amount"] for r in state.funding_history),
    }


# ─── Matrix runner ───────────────────────────────────────────────────────────

TYPES = ["saas", "consumer", "marketplace", "dev_tools"]
DIFFS = ["sandbox", "normal", "hardcore"]
RUNS_PER_CELL = 3  # run multiple seeds per cell for variance


def run_matrix(type_filter: Optional[str] = None, diff_filter: Optional[str] = None,
               scenario: str = DEFAULT_SCENARIO, verbose: bool = False):
    types = [type_filter] if type_filter else TYPES
    diffs = [diff_filter] if diff_filter else DIFFS

    results = []
    for tk in types:
        for dk in diffs:
            for strat in STRATEGIES:
                for seed in range(RUNS_PER_CELL):
                    r = run_simulation(tk, dk, strat, scenario=scenario,
                                       seed=seed * 42 + hash(tk + dk), verbose=verbose)
                    results.append(r)

    return results


def print_summary(results: list):
    # Group by (type, difficulty)
    cells = {}
    for r in results:
        key = (r["type"], r["difficulty"])
        cells.setdefault(key, []).append(r)

    print()
    print("=" * 100)
    print(f"{'TYPE':<14} {'DIFF':<10} {'WINS':>5} {'LOSSES':>7} {'AVG Q':>6} {'AVG USERS':>10} "
          f"{'AVG REV/Q':>10} {'AVG CASH':>10} {'CASH FLOOR':>11} {'1st FEAT':>9}")
    print("-" * 100)

    for tk in TYPES:
        for dk in DIFFS:
            key = (tk, dk)
            runs = cells.get(key, [])
            if not runs:
                continue

            wins = sum(1 for r in runs if r["end_reason"].startswith("win"))
            losses = sum(1 for r in runs if not r["end_reason"].startswith("win") and r["end_reason"] != "timeout")
            avg_q = sum(r["quarter_reached"] for r in runs) / len(runs)
            avg_users = sum(r["users"] for r in runs) / len(runs)
            avg_rev = sum(r["revenue_per_q"] for r in runs) / len(runs)
            avg_cash = sum(r["cash"] for r in runs) / len(runs)
            avg_floor = sum(r["cash_floor"] for r in runs) / len(runs)
            avg_feat_q = sum(r["first_feature_q"] for r in runs) / max(1, sum(1 for r in runs if r["first_feature_q"] > 0))

            flag = ""
            if dk == "normal" and wins == 0:
                flag = " ⚠️  NO WINS ON NORMAL"
            elif dk == "hardcore" and wins == len(runs):
                flag = " ⚠️  TOO EASY FOR HARDCORE"
            elif dk == "sandbox" and losses > 0:
                flag = " ⚠️  LOSSES ON SANDBOX"

            print(f"{tk:<14} {dk:<10} {wins:>5}/{len(runs):<2} {losses:>5} {avg_q:>6.1f} "
                  f"{avg_users:>10,.0f} {avg_rev:>10,.0f} {avg_cash:>10,.0f} "
                  f"{avg_floor:>11,.0f} {'Q'+str(round(avg_feat_q)):>9}{flag}")

        print()

    # Per-strategy breakdown
    print()
    print("=" * 80)
    print("STRATEGY BREAKDOWN (all cells)")
    print("-" * 80)
    for strat in STRATEGIES:
        strat_runs = [r for r in results if r["strategy"] == strat]
        wins = sum(1 for r in strat_runs if r["end_reason"].startswith("win"))
        avg_q = sum(r["quarter_reached"] for r in strat_runs) / max(1, len(strat_runs))
        avg_users = sum(r["users"] for r in strat_runs) / max(1, len(strat_runs))

        end_reasons = {}
        for r in strat_runs:
            end_reasons[r["end_reason"]] = end_reasons.get(r["end_reason"], 0) + 1

        reason_str = ", ".join(f"{k}:{v}" for k, v in sorted(end_reasons.items()))
        print(f"  {strat:<15} wins={wins}/{len(strat_runs)}  avgQ={avg_q:.1f}  avgUsers={avg_users:,.0f}  [{reason_str}]")

    # Flag issues
    print()
    print("=" * 80)
    print("BALANCE ISSUES")
    print("-" * 80)
    issues = []
    for tk in TYPES:
        normal_runs = [r for r in results if r["type"] == tk and r["difficulty"] == "normal"]
        normal_wins = sum(1 for r in normal_runs if r["end_reason"].startswith("win"))
        if normal_runs and normal_wins == 0:
            issues.append(f"❌ {tk} Normal: NO wins across any strategy — game may be unwinnable")
        elif normal_runs and normal_wins < len(normal_runs) * 0.3:
            issues.append(f"⚠️  {tk} Normal: Low win rate ({normal_wins}/{len(normal_runs)}) — may need easier tuning")

        sandbox_runs = [r for r in results if r["type"] == tk and r["difficulty"] == "sandbox"]
        sandbox_losses = sum(1 for r in sandbox_runs if not r["end_reason"].startswith("win") and r["end_reason"] != "timeout")
        if sandbox_runs and sandbox_losses > 0:
            issues.append(f"❌ {tk} Sandbox: {sandbox_losses} losses — sandbox should be nearly unlosable")

        hardcore_runs = [r for r in results if r["type"] == tk and r["difficulty"] == "hardcore"]
        hardcore_wins = sum(1 for r in hardcore_runs if r["end_reason"].startswith("win"))
        if hardcore_runs and hardcore_wins == len(hardcore_runs):
            issues.append(f"⚠️  {tk} Hardcore: 100% win rate — should be harder")

    if issues:
        for i in issues:
            print(f"  {i}")
    else:
        print("  ✅ No critical balance issues detected")

    print()


def main():
    parser = argparse.ArgumentParser(description="VENTURE balance simulation runner")
    parser.add_argument("--type", choices=TYPES, help="Company type filter")
    parser.add_argument("--diff", choices=DIFFS, help="Difficulty filter")
    parser.add_argument("--scenario", choices=list(SCENARIOS.keys()), default=DEFAULT_SCENARIO)
    parser.add_argument("--verbose", "-v", action="store_true", help="Print per-quarter details")
    parser.add_argument("--runs", type=int, default=3, help="Seeds per cell (default: 3)")
    args = parser.parse_args()

    global FEATURE_CATALOG, RUNS_PER_CELL
    FEATURE_CATALOG = load_features()
    RUNS_PER_CELL = args.runs

    types_count = len(TYPES if not args.type else [args.type])
    diffs_count = len(DIFFS if not args.diff else [args.diff])
    print(f"Scenario: {args.scenario} (${SCENARIOS[args.scenario]['cash']:,} start)")
    print(f"Running: {types_count} types × {diffs_count} difficulties × "
          f"{len(STRATEGIES)} strategies × {RUNS_PER_CELL} seeds = "
          f"{types_count * diffs_count * len(STRATEGIES) * RUNS_PER_CELL} runs")

    results = run_matrix(args.type, args.diff, args.scenario, args.verbose)
    print_summary(results)


if __name__ == "__main__":
    main()
