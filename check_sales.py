import json
import sys

data = json.load(sys.stdin)

double_sales = []
for sale in data:
    for item in sale['saleItems']:
        qty = item.get('quantity', 0)
        if isinstance(qty, (int, float)) and qty % 1 != 0:
            double_sales.append(sale)
            break

print(f'Topildi {len(double_sales)} ta double quantity li sale\n')

for sale in double_sales[:5]:
    print(f"Sale ID: {sale['id'][:8]}...")
    print(f"  Status: {sale['status']}")
    print(f"  Date: {sale['createdAt']}")
    print(f"  Double items:")
    for item in sale['saleItems']:
        qty = item.get('quantity', 0)
        if isinstance(qty, (int, float)) and qty % 1 != 0:
            print(f"    - {item['productName']}: {qty} ta")
    print()
