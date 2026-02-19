# EA Framework（MetaTrader 5 アルゴリズム取引フレームワーク）

> コンストラクタDIとインターフェース契約に基づき、EA（Expert Advisor）の戦略部分を差し替えるだけで新規EAを量産できるMQL5フレームワーク

---

## 注意点

本リポジトリには開発途中のEA、検証用ファイル、過去バージョン（MyTradeModules20251030 / 20251109 / 20251203 等）を含みます。バージョン管理によりフレームワークの進化過程を追跡できます。

---

## 概要

本プロジェクトは、MetaTrader 5（MT5）上でアルゴリズム取引を行うEA開発のための**再利用可能なフレームワーク**です。  
注文執行・ポジション管理・シグナル判定・ロット計算などを**役割別モジュール**に分離し、EA本体（.mq5）は「部品を組み立てるだけ」で戦略が完成する設計です。

---

## アーキテクチャ

### 設計パターン

| パターン | 適用箇所 | 効果 |
|----------|----------|------|
| **Dependency Injection** | コンストラクタ経由で Order / Position / BarData を注入 | 固定インフラとロジックを分離し、テスト・差し替えが容易 |
| **Strategy Pattern** | `C_EntryBase`, `C_ExitBase`, `C_FilterBase` 等の抽象基底クラス | エントリー・決済・フィルタをプラグインとして交換可能 |
| **Template Method** | `C_ActionBase::Process()` を契約とした実装 | 各ロジックが同一インターフェースに従い、フレームから一括呼び出し |
| **Single Responsibility** | モジュール単位の分割 | 注文・ポジション・セッション・シグナル・ロットを独立して保守 |

### 実行フロー

```
OnTick() → Exit.Process() → Positionチェック → Buy.Process() / Sell.Process()
```

決済を優先し、ポジションがある場合はエントリーをスキップするフロー制御を実装。

---

## 技術的な実装ポイント

### OrderModule（注文執行）

- **ブローカー互換**: `SYMBOL_FILLING_MODE` のビット判定により FOK / IOC / RETURN を自動選択
- **SL/TP検証**: `SYMBOL_TRADE_STOPS_LEVEL` に基づく最小距離チェック、未満時は発注を中止
- **価格正規化**: `SymbolInfoDouble(SYMBOL_POINT)` と `NormalizeDouble()` で桁数・刻みを考慮
- **エラーハンドリング**: `OrderSend` 失敗時・`retcode` 異常時に警告ログ出力と `ResetLastError()`

### PositionModule（ポジション管理）

- **スナップショットパターン**: `CopyStArray()` で構造体配列にコピーし、イミュータブルな状態を取得
- **Magic・Symbol フィルタ**: EA専用ポジションのみを対象に抽出

### LotSizeModule（ロット計算）

- **リスクベース算出**: `risk_per × balance / max_loss` でポジションサイズを決定
- **WFA連携**: `WFA_max_loss` により Walk-Forward Analysis で得た最大損失を入力可能
- **刻み幅対応**: `SYMBOL_VOLUME_STEP` に基づく `MathFloor` と正規化

### SignalModule（シグナル・データ）

- **C_Indicator**: デストラクタで `IndicatorRelease()` を呼び出し、ハンドルのリークを防止（RAII）
- **C_BarData**: `ArraySetAsSeries(true)` による時系列インデックス、バッファ境界チェック

### SessionModule（セッション制御）

- **曜日×時間帯**: `IsActiveSession()` で曜日と時間帯を同時判定
- **日跨ぎ対応**: `start_hour > end_hour` の場合のオーバーナイト時間帯をサポート

### 戦略モジュールの共通設計

- **新バー検出**: `current_bar.time == _last_time` による同一ティック内の重複エントリー防止
- **ポジション有無チェック**: 既存ポジションがある場合はエントリーをスキップ（オプション）

---

## プロジェクト構成

```
├── MyExpertAdvisors/          # EA実装例（TestMA、各種 LimitedTest 版）
│   └── Modules/               # Frame, Buy, Sell, Exit, Filter, Parameter
├── Versions/
│   ├── MyTradeModules*/       # コアフレームワーク（EAFrame、6種モジュール）
│   └── TestModules*/          # 検証用 Entry/Exit 実装（差し替えテスト）
```

### コアモジュール（MyTradeModules）

| モジュール | 役割 |
|------------|------|
| **EAFrame** | 抽象基底クラス、Action/Filter/LotSizer/SLTP のインターフェース定義 |
| **OrderModule** | 新規注文・決済・ModifySLTP、MqlTradeRequest/Result の扱い |
| **PositionModule** | ポジション一覧取得、POSITION 構造体によるデータ受け渡し |
| **SessionModule** | 曜日・時間帯による取引可否判定 |
| **SignalModule** | C_Indicator（インジケータラッパ）、C_BarData（4本値取得） |
| **LotSizeModule** | リスクベース・WFA 対応のロット計算 |

### 検証・戦略モジュール（TestModules）

| モジュール | 戦略種別 | 概要 |
|------------|----------|------|
| **RSIEntry** | カウンタートレンド | RSI の過買い・過売り水準（30/70）でエントリー |
| **BreakoutEntry** | トレンドフォロー | N本足の高値/安値ブレイクアウトでエントリー |
| **FixedSLTPClose** | 決済 | エントリー価格からの固定ポイントで SL/TP を ModifySLTP |
| **FixedBarsClose** | 決済 | 一定バー数経過で決済 |

---

## EAの差し替え例

コンストラクタで Entry を差し替えるだけで、同じ Frame を流用して別戦略のEAを生成：

```cpp
class C_Frame_RSIEntry : public C_Frame
{
    C_Frame_RSIEntry(...) : C_Frame(...)
    {
        // 親で生成された Entry を RSI 版に差し替え
        if(buy != NULL) delete buy;
        buy = new C_RSIBuy(&order, &position, &bar, sym, period);
        if(sell != NULL) delete sell;
        sell = new C_RSISell(&order, &position, &bar, sym, period);
    }
};
```

---

## 目的・設計思想

1. **共通処理の分離**：戦略部分を差し替えやすくし、検証・比較を効率化
2. **役割の明確化**：注文、ポジション、セッション、シグナル、ロット計算をモジュール単位で管理
3. **保守性の重視**：Walk-Forward Analysis やバックテストの反復を前提とした、保守しやすい構造

---

## 開発環境

- **プラットフォーム**: MetaTrader 5
- **言語**: MQL5

---

*アルゴリズムトレード・EA開発の学習・研究目的で開発・運用しています。*
