# synthetic-data

Iceberg Lab에 넣을 **전자상거래 Parquet** (`customers`, `products`, `orders`)를 만듭니다.

**Python 3.8+ 필수.** RHEL edge에서 `python` 이 **Python 2.7** 이면 f-string 에서 `SyntaxError` 가 납니다. 반드시 **`python3`** 를 사용하세요.

## 방법 1 — 저장소 루트에서 (권장)

```bash
cd ~/iceberg-complete-lab
chmod +x scripts/generate_synthetic_data.sh   # 최초 1회
./scripts/generate_synthetic_data.sh --rows-customers 1000 --rows-orders 5000
```

출력: `synthetic-data/samples/*.parquet`

## 방법 2 — synthetic-data 디렉터리에서

이미 `synthetic-data` 안에 있다면 **`cd synthetic-data` 를 다시 하지 마세요.**

```bash
cd ~/iceberg-complete-lab/synthetic-data
python3 -m pip install -r requirements.txt
python3 generators/generate_ecommerce_data.py --rows-customers 1000 --rows-orders 5000
```

## 확인

```bash
python3 --version    # 3.8 이상
ls -la samples/*.parquet
```
