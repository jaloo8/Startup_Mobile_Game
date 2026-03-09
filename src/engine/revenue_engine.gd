class_name RevenueEngine
extends RefCounted
## Calculates quarterly revenue based on company type and product metrics.

static func calculate(company: CompanyData, product: ProductData) -> float:
	var base: float
	match company.type:
		CompanyData.CompanyType.SAAS:
			base = _saas_revenue(product)
		CompanyData.CompanyType.CONSUMER:
			base = _consumer_revenue(product)
		CompanyData.CompanyType.MARKETPLACE:
			base = _marketplace_revenue(product)
		CompanyData.CompanyType.DEV_TOOLS:
			base = _devtools_revenue(product)
		_:
			base = 0.0
	return maxf(0.0, base * product.revenue_mult)


static func _saas_revenue(product: ProductData) -> float:
	var paying_users := product.users * 0.05  # 5% conversion to paid
	var arpu := 20.0  # avg revenue per user per month
	return paying_users * arpu * 3  # quarterly


static func _consumer_revenue(product: ProductData) -> float:
	var ad_revenue := product.dau * 0.02 * 90  # CPM-based, per day * days
	var premium_pct := 0.03
	var premium_revenue := product.users * premium_pct * 5.0 * 3
	return ad_revenue + premium_revenue


static func _marketplace_revenue(product: ProductData) -> float:
	var gmv_per_user := 50.0
	var take_rate := 0.10
	return product.users * gmv_per_user * take_rate * 3


static func _devtools_revenue(product: ProductData) -> float:
	var api_calls_per_user := 1000.0
	var price_per_call := 0.001
	return product.users * api_calls_per_user * price_per_call * 3
