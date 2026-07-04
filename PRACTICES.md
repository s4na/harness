# ハーネス収録プラクティス一覧

1行 = 1プラクティス。各行はそのままスキルの原則行・lintルール・レビュー観点の種になる。出典系統: Anthropic engineering blog(context/harness/tools)、react.dev、Rust API Guidelines、Effective Go / Google Go Style Guide、HashiCorp・Google Terraform style guide、strong_migrations、VoidZero docs。

---

## core: DB・スキーマ設計原則

- 状態を汎用 `status` カラム1本で持たず、イベント発生時刻の `xxx_at`(NULL=未発生)カラム群で表現し、現在状態は導出する
- 状態が5個を超える・遷移履歴の監査が必要なら、`xxx_at` でなく append-only のイベント(遷移)テーブルに正規化する
- boolean カラムは必ず NOT NULL + DEFAULT を付け、3値論理(true/false/NULL)を作らない
- 「いつそうなったか」に意味がある boolean は `xxx_at` timestamp に置き換える
- 参照整合性はアプリのバリデーションでなく DB の FOREIGN KEY 制約で保証する
- 一意性は UNIQUE INDEX で保証する(アプリ層の uniqueness 検証は並行リクエストで破れる)
- NOT NULL をデフォルトとし、NULLABLE にする場合は理由を ADR かカラムコメントに残す
- 金額に float を使わず、decimal 型または最小通貨単位の整数(cents)で持つ
- 時刻は UTC で保存し、PostgreSQL では timestamptz を使う
- 主キーは bigint シーケンスまたは UUIDv7 とし、UUIDv4(ランダム)はインデックス局所性の悪化を理由に避ける
- 論理削除(soft delete)を安易に採用せず、採用時は `deleted_at` + partial unique index で一意性を維持する
- 全テーブルに created_at / updated_at を付ける
- enum は DB に文字列(または native enum)で保存し、整数へのマッピングをアプリ内に隠さない
- 中間テーブルに属性が生えた時点で独立モデルに昇格させる(has_many :through)
- 集計値の非正規化(counter cache 等)には必ず再計算による整合性回復手段をセットで用意する
- 正数・値域などのドメイン制約は CHECK 制約で DB に置く

## core: コードレビュー

- 指摘は Blocking / Should-fix / Nit の3段階重大度でラベル付けする
- 全指摘に file:line を添える
- レビュアーはコードを書き直さず、問題・理由・方向性の指摘に徹する
- 変更されたコードパスのテスト有無を必ず確認し、欠落を明示的に指摘する
- 正常系だけでなくエラーパス・境界値・並行実行時の振る舞いを確認する
- diff 外への影響(呼び出し元、マイグレーション適用順、デプロイ順序)を確認する
- レビューは「Ready to ship / Address blockers then ship / Needs another pass」の一行結論で締める

## core: ADR 運用

- 設計判断が発生したその場で ADR に記録する(1判断 = 1ファイル、連番)
- ADR は Context / Decision / Consequences の3部構成で書く
- 却下した代替案と却下理由を必ず併記する
- ADR は不変とし、判断を覆すときは新 ADR で supersede して旧 ADR を書き換えない
- スキル内の全ての「〜すべき」は対応する ADR へのリンクを持つ

---

## rails

- default_scope を使わない
- callback から外部副作用(メール送信・外部 API・enqueue)を起こさない。必要なら after_commit に限定する
- DB トランザクション内で外部 API 呼び出し・job enqueue をしない
- job の enqueue は after_commit で行う(コミット前 enqueue はレコード未可視のレースを生む)
- ActiveJob は at-least-once 配信を前提に冪等(idempotent)に実装する
- N+1 は includes / preload / eager_load で解消し、strict_loading と Prosopite を CI で有効化して再発を機械検出する
- uniqueness バリデーションには必ず対応する UNIQUE INDEX を併設する
- マイグレーションは strong_migrations でゲートし、後方互換の expand → contract 2段階で行う
- スキーマ変更とデータ移行(backfill)を同一マイグレーションに混ぜない
- scope は必ず lambda で定義する
- 手続き的ロジックは PORO の Service / Form / Query オブジェクトへ抽出し、永続化・関連の責務は ActiveRecord に残す
- Concern は複数モデルで共有する振る舞いにのみ使い、単一モデルのコード分割に使わない
- SQL の組み立てに文字列連結を使わず、プレースホルダまたは Arel を使う
- 許可属性は params.expect(Rails 8+)/ strong parameters で明示する
- 秘密情報は credentials または ENV で管理し、リポジトリに平文で置かない
- update_all / delete_all / update_column は callback・validation をスキップする前提を理解した箇所でのみ使う
- Time.now でなく Time.current を使う(アプリ timezone 考慮)
- find_each / in_batches を使い、大量レコードの all.each を書かない
- テストは model spec と request spec を主体にし、system spec はクリティカルフローに絞る
- FactoryBot の factory は最小の有効レコードを定義し、関連の自動生成連鎖を避ける
- RuboCop は共有 gem を inherit_gem で継承し、プロジェクトの .rubocop.yml には差分のみ書く

---

## typescript(VoidZero スタック)

- strict: true に加え noUncheckedIndexedAccess / noImplicitOverride / exactOptionalPropertyTypes を有効化する
- any を禁止し、型不明の外部入力は unknown で受けて型ガード(narrowing)で絞る
- 型アサーション(as)は最終手段とし、形状検証には satisfies を優先する
- enum を使わず、as const オブジェクトまたは文字列リテラル union を使う
- 状態は boolean フラグの組合せでなく判別可能ユニオン(discriminated union)で表現し、switch の網羅性を never 代入で保証する
- 実行時境界(API 応答・フォーム・環境変数)は zod / valibot 等のスキーマで parse し、型と実行時値を一致させる(parse, don't validate)
- default export を避け named export に統一する
- barrel file(index.ts での re-export 集約)を作らない(tree-shaking 阻害と循環 import の温床)
- パッケージは ESM-only とし、package.json の exports field でエントリポイントを明示する
- ライブラリの公開 API には明示的な型注釈を書き、isolatedDeclarations 互換に保つ
- 欠損値は原則 undefined に寄せ、null との使い分け方針をリポジトリで統一する
- 構造的型付けで混同しうる ID・単位には branded type(newtype)を使う
- Pick / Omit / Partial の深いネストより、意味のある名前付き型を定義する
- ツールチェーンは Vite+(vp)に統一し、フォーマット・lint・型検査を vp check の1コマンドに集約する
- lint は Oxlint、フォーマットは Oxfmt を使い、ルールは @org/oxlint-config として npm 配布して各プロジェクトが継承する
- 型検査は tsgo(tsgolint)で行い、CI の型検査時間を Node 実装に律速させない
- ライブラリのバンドルは tsdown、アプリのビルドは Vite(Rolldown)を使う
- pre-commit は Vite+ の staged hooks(`'*': 'vp check --fix'`)で強制する
- Vite+ に乗れないプロジェクトは oxlint.config.ts / oxfmt.config.ts の単体構成に切り替え、共有 config は同一物を参照する

---

## react

- 派生値を useState + useEffect で同期せず、レンダー中に計算する(derived state is not state)
- useEffect は外部システムとの同期専用とし、データ取得・イベント応答・状態変換に使わない
- サーバ状態は TanStack Query 等のキャッシュ層に置き、useEffect + useState の手書き fetch を書かない
- React Compiler を有効化し、手動の memo / useMemo / useCallback を新規に書かない
- Rules of React(レンダー純粋性・props/state の不変性)を lint で強制する(違反コンポーネントは Compiler 最適化がスキップされる)
- key に配列 index を使わず、安定した一意 ID を使う
- props を useState の初期値にコピーしない。prop 変化でのリセットは key による再マウントで行う
- 状態は使用箇所の最近傍に置き(colocation)、共有が必要になるまでリフトアップしない
- バリアントを boolean props の増殖で表現せず、children と composition で解決する
- 1つの Context に変更頻度の異なる値を同居させず、値と更新関数を別 Context に分割する
- フォームは useActionState / form actions(または react-hook-form)を使い、全 input の onChange + useState 手動管理をしない
- 非同期 UI は Suspense + ErrorBoundary の境界で宣言し、loading / error フラグの手動管理を減らす
- 楽観的更新は useOptimistic を使う
- effect 内で最新値を読むが再実行トリガーにしたくない値は useEffectEvent で扱う
- ロジックは custom hook に抽出し、コンポーネント本体は JSX の宣言に近づける
- dangerouslySetInnerHTML を使わない(不可避ならサニタイズをユーティリティで強制する)
- semantic HTML を優先し、ARIA は不足分のみ付与、jsx-a11y 相当の lint を CI で強制する
- テストは Testing Library でユーザ視点に立ち、クエリは getByRole を優先、testId は最終手段とする
- イベントは fireEvent でなく userEvent を使う
- ネットワークは MSW でモックし、モジュールモックを避ける
- コンポーネントテストは Vitest browser mode で実ブラウザ実行する

---

## go

- エラーは握りつぶさず、`fmt.Errorf("...: %w", err)` で文脈を付けて呼び出し元へ返す
- エラー判定は errors.Is / errors.As を使い、文字列比較をしない
- panic はプログラミングバグ(不変条件違反)専用とし、回復可能なエラーに使わない
- context.Context は第一引数 ctx で受け渡し、struct フィールドに保存しない
- interface は提供側でなく利用側パッケージで定義し、メソッド数を最小に保つ(accept interfaces, return structs)
- goroutine は終了経路(context cancel / channel close)を設計してから起動する
- 並行処理の集約は errgroup / sync.WaitGroup を使い、生の channel 編みを最小化する
- 共有状態の保護はまず sync.Mutex を検討し、channel は所有権移転とパイプラインに使う
- ゼロ値がそのまま有効に使える型設計にする(useful zero value)
- パッケージ名は小文字・単数の名詞とし、util / common / helpers を禁止する
- 公開識別子を最小化し、internal/ で意図しない import を防ぐ
- 依存はコンストラクタ引数で明示的に注入し、DI コンテナとパッケージレベル変数を避ける
- テストは table-driven で書き、t.Run でサブテスト化し、可能な限り t.Parallel を付ける
- time.Now・乱数・外部 I/O は関数またはインターフェースで注入し、テストで差し替え可能にする
- golangci-lint を共有設定で運用し、errcheck / govet / staticcheck を必須にする
- guard clause の早期 return でネストを浅く保つ(happy path を左端に揃える)
- 要素数が既知のスライスは make で cap を事前確保する

---

## rust

- clippy を `-D warnings` で運用し、cargo fmt を CI で強制する
- 本番コードで unwrap を使わない。不変条件が保証済みの箇所のみ expect で理由を書く
- エラーは `?` で伝播し、ライブラリは thiserror の型付きエラー、アプリケーションは anyhow + context を使う
- 関数引数は借用(&str / &[T] / impl AsRef)で受け、所有権(String / Vec)は保持が必要な時のみ受け取る
- 不正な状態を型で表現不能にする(make invalid states unrepresentable): enum と newtype で状態空間を制限する
- 素の u64 / String の ID・単位は newtype でラップし、取り違えをコンパイルエラーにする
- match は網羅的に書き、`_` ワイルドカードアームで enum バリアント追加時の検出を潰さない
- unsafe は最小のモジュールに隔離し、各ブロックに `// SAFETY:` で成立条件を記述する
- 公開 API は Rust API Guidelines(C-CONV / C-GETTER 等の命名規約)に準拠する
- borrow checker からの逃げとして clone を乱用せず、共有が本質なら Rc / Arc を意図して選ぶ
- 依存は cargo-deny(license / bans / advisories)と cargo-audit を CI で回す
- 複雑な構築はビルダーパターンまたは typestate で型安全にする
- トレイト境界は struct 定義でなく impl / 関数側の where に書く
- クレートが育ったら workspace で分割し、ビルド時間と公開境界を管理する
- 手書き index ループよりイテレータチェーンを優先する

---

## terraform

- state はリモートバックエンドに置き、ロックと保存時暗号化を必須にする
- 環境分離は workspace でなくディレクトリ(またはリポジトリ)分離で行う
- module は「共に変更されるリソース群」単位で薄く作り、ルートモジュールで合成する
- 単一リソースの薄いラッパー module を作らない
- variable には type と description を必須とし、制約は validation ブロックで表現する
- count でなく for_each を使う(要素の並び替えによる意図しない再作成を防ぐ)
- 命名は snake_case、種別内で唯一のリソースは `this` と命名する
- required_providers と required_version を明示し、.terraform.lock.hcl をコミットする
- 秘密情報は state に平文で載る前提で設計し、値は SSM / Secrets Manager 参照か ephemeral values で注入する
- ARN / ID のハードコードを避け、data source または remote state 参照にする
- リソースの移動・改名は moved ブロックで宣言し、terraform state mv の手作業を避ける
- 消失が致命的なリソースには lifecycle prevent_destroy を付ける
- terraform fmt / validate / tflint / trivy を CI の必須ゲートにする
- plan 出力を PR に添付し、人間の approve なしに apply しない(plan と apply のパイプライン分離)
- output にも description を付け、module の公開契約として扱う
- locals で式の重複を排除し、条件式のネストを避ける

---

## prompt engineering

- 指示は明確・直接に書き、「適切に」「いい感じに」等の曖昧語を成功条件の明示に置き換える
- 指示・データ・例は XML タグで構造的に区切り、混在させない
- few-shot 例は多様で正準的(canonical)なものを少数厳選し、エッジケースの羅列で埋めない
- 禁止事項の列挙より「何をすべきか」の肯定形で指示する
- 長文コンテキストでは文書・データを先頭、指示を末尾に配置する
- 結論の前に根拠の引用・抽出をさせる(grounding)
- 出力形式は散文の説明でなくスキーマまたは出力例で指定する
- 役割・トーン・不変ルールは system prompt、タスク固有の指示は user message に置く
- テンプレート変数は明示的なデリミタで囲い、ユーザ入力と指示を構造的に分離する(prompt injection 対策を兼ねる)
- 多段推論が必要なタスクは extended thinking を許可し、単純なワンショット分類には使わない
- プロンプトの変更は必ず eval の回帰で検証し、eval なしの本番プロンプト修正を禁止する
- temperature はタスク種別(抽出=低 / 生成=高)ごとに固定し、都度いじらない
- モデルが既に知っている一般知識をプロンプトで再説明しない(コンテキストは有限資源)

---

## harness engineering

- コンテキストを有限の attention budget として扱い、載せる情報はトークンの限界効用で選ぶ
- system prompt は「適切な高度」で書く: 分岐を全列挙するハードコードでも、曖昧な高レベル指示でもない中間
- ツールセットは最小に保ち、人間がどちらを使うか即答できない機能重複ツールを置かない
- ツールの description には目的・入出力・使用条件を書き、エラーメッセージは次アクションを示す(actionable error)
- 大量データを返しうるツールには pagination / filtering / truncation と応答トークン上限を実装する
- 知識は事前の全量注入でなく just-in-time retrieval(パス・検索による必要時取得)を基本にする
- 長期タスクは compaction(要約して新ウィンドウへ)・構造化メモ(NOTES.md 等への外部化)・サブエージェント分割の3手法を使い分ける
- サブエージェントには探索・調査を委譲し、親コンテキストには蒸留済みの結果だけを返す
- コンテキスト圧迫時は compaction より新規ウィンドウ + ファイルシステムからの状態復元を先に検討する
- スキルの発火は description が全て: 「何をするか + いつ使うか + トリガー語」を書き、undertrigger 傾向に合わせてやや強めに書く
- description には「いつ使わないか」も書き、複数スキル同時発火環境での誤発火を抑える
- SKILL.md 本文は 500 行以内、詳細は references/ に分離して progressive disclosure に従う
- 決定論的に実行できる処理は LLM に判断させずスクリプト化してスキルに同梱する
- 破壊的操作(force push / rm -rf / DROP)は hooks・permission で機械的にブロックし、プロンプトの注意書きに頼らない
- AGENTS.md / CLAUDE.md は簡潔な目次に保ち、詳細はスキル・参照ファイルへの段階開示に委ねる
- lint・型検査・テストの高速なフィードバックループを整備する(エージェントの実効性能は検証手段の質で決まる)
- 長時間タスクでは初期化フェーズで要件リスト・テスト・進捗ファイルを整備し、後続エージェントがファイルシステムから状態復元できるようにする
- ハーネスの変更(スキル・プロンプト・ツール)は eval のタスク成功率とスキル発火率の回帰で検証する
- 同じ説明を2回したらスキル化、同じ事故が2回起きたら lint / hook 化する(判断の資産化パイプライン)
