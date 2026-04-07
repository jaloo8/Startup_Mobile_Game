class_name RevenueEngine
extends RefCounted
## Calculates quarterly revenue based on company type and product metrics.

static func calculate(company: CompanyData, product: ProductData) -> float:
	if company == null or product == null:
		push_error("RevenueEngine.calculate: null company or product")
		return 0.0
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
			push_warning("RevenueEngine: unrecognized company type %d" % company.type)
			base = 0.0
	var niche_mult := clampf(company.niche_revenue_mult, 0.6, 1.6)
	return maxf(0.0, base * product.revenue_mult * niche_mult)


static func _saas_revenue(product: ProductData) -> float:
	var paying_users := product.users * 0.06  # 6% freemium-to-paid conversion
	var arpu := 28.0  # avg revenue per paying user per month (realistic B2B SaaS)
	return paying_users * arpu * 3  # quarterly


static func _consumer_revenue(product: ProductData) -> float:
	var ad_revenue := product.dau * 0.06 * 90  # realistic CPM for engaged mobile users
	var premium_pct := 0.06  # 6% premium conversion
	var premium_revenue := product.users * premium_pct * 8.0 * 3
	return ad_revenue + premium_revenue


static func _marketplace_revenue(product: ProductData) -> float:
	var gmv_per_user := 65.0  # higher GMV per active user
	var take_rate := 0.10
	return product.users * gmv_per_user * take_rate * 3


static func _devtools_revenue(product: ProductData) -> float:
	var api_calls_per_user := 1200.0  # higher API call volume at early stage
	var price_per_call := 0.0012  # slightly higher price per call
	return product.users * api_calls_per_user * price_per_call * 3
