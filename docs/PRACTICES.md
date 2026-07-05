# ハーネス収録プラクティス一覧(徹底版)

1行 = 1プラクティス。各行はそのままスキルの原則行・lintルール・レビュー観点・ADRの種になる。
出典系統: Anthropic engineering blog(context engineering / effective harnesses / writing tools / code execution with MCP)、react.dev、Rust API Guidelines、Effective Go / Google Go Style Guide、Use The Index Luke / PostgreSQL docs、strong_migrations、HashiCorp・Google Terraform style guide、VoidZero docs。

---

## core: DB・スキーマ設計

### 状態のモデリング

- 状態を汎用 `status` カラム1本で持たず、イベント発生時刻の `xxx_at`(NULL = 未発生)カラム群で表現し、現在状態は導出する
- `xxx_at` 方式は「単調に進む・後戻りしない」ライフサイクルに使い、後戻り・分岐する状態機械には使わない
- 状態が多い・遷移履歴の監査が必要・遷移に付随データがあるなら、append-only のイベント(遷移)テーブルに正規化し、現在状態はビューか最新行から導出する
- 状態遷移には許可された遷移の表(state machine 定義)をコードで一元管理し、任意の状態間更新を禁止する
- 「is_xxx な boolean」は「いつそうなったか」に意味があるなら `xxx_at` timestamp に置き換える
- 相互排他な複数 boolean(is_draft, is_published…)を作らず、単一の状態表現に統合する
- ワークフロー種別ごとに意味が違う状態を1カラムに混ぜない(注文状態と決済状態を分ける)

### 制約: アプリでなく DB に置くもの

- 参照整合性は FOREIGN KEY 制約で保証し、ON DELETE の挙動(RESTRICT / CASCADE / SET NULL)を明示的に選ぶ
- 一意性は UNIQUE INDEX で保証する(アプリ層の uniqueness 検証は並行リクエストの TOCTOU で破れる)
- NOT NULL をデフォルトとし、NULLABLE を選ぶ場合は「NULL の意味」をカラムコメントか ADR に定義する
- 値域・正数・組合せ条件は CHECK 制約で表現する(例: `price_cents >= 0`、`ends_at > starts_at`)
- 条件付き一意(有効レコードのみ一意)は partial unique index で表現する
- 大文字小文字を無視した一意は citext または式インデックス(`LOWER(email)`)で保証する
- 排他期間(予約の重複禁止)は EXCLUDE 制約 + 範囲型で表現する
- boolean は NOT NULL + DEFAULT を必須とし、3値論理(true / false / NULL)を作らない
- 制約・インデックスには規約に沿った名前を明示的に付ける(自動生成名は変更検知とエラーメッセージを悪化させる)

### 型の選択

- 金額は float / real を禁止し、最小通貨単位の整数(cents)+通貨コードカラム、または decimal で持つ
- 時刻は UTC で保存し、PostgreSQL では timestamp でなく timestamptz を使う
- 「日付」概念(誕生日・締切日)には date 型を使い、timestamp に 00:00 を詰めない
- 主キーは bigint identity または UUIDv7 とし、UUIDv4 は B-tree の書き込み局所性悪化を理由に避ける
- int の主キーは作らない(20億で枯渇する。最初から bigint)
- 外部公開する ID は連番を直接晒さず、UUID か別の public_id を持つ(採番数・順序の情報漏洩を防ぐ)
- enum 値は文字列(または DB native enum)で保存し、整数マッピングをアプリ内に隠さない
- 可変長文字列は varchar(n) の恣意的な n をやめ text + 必要なら CHECK で上限を課す(PostgreSQL)
- 電話番号・郵便番号・各種コードは数値型でなく文字列で持つ(先頭ゼロ・ハイフン・国際化)
- JSONB は「スキーマが本質的に不定」なデータ専用とし、検索・JOIN・制約の対象になる属性は正規カラムに昇格させる
- 配列カラム・カンマ区切り文字列で多対多を表現しない(第一正規形)

### インデックス設計

- 外部キーカラムには明示的にインデックスを張る(PostgreSQL は FK に自動でインデックスを作らない)
- 複合インデックスは「等値条件のカラムを先、範囲条件のカラムを後」の順に並べる
- 複合インデックス (a, b) があるとき (a) 単独のインデックスは冗長なので張らない
- インデックスは書き込みコストとの交換であることを前提に、使われていないインデックスを定期監査する(pg_stat_user_indexes)
- 特定条件の行だけ検索するクエリには partial index を検討する(例: `WHERE deleted_at IS NULL`)
- 関数適用した検索には式インデックスを張る(インデックス列に関数を掛けるとインデックスは使われない)
- LIKE '%foo%' の中間一致には B-tree でなく pg_trgm + GIN を使う
- カーディナリティの極端に低いカラム単独のインデックスは効果を疑う(プランナに選ばれない)
- covering index(INCLUDE)で index-only scan を狙える読み取りホットパスを特定する

### ロック・並行性

- 読んで計算して書く更新は、楽観ロック(lock_version)か SELECT ... FOR UPDATE のどちらで守るかを明示的に選ぶ
- 在庫・残高のようなカウンタ更新は `UPDATE ... SET x = x + ?` の原子更新にし、read-modify-write をしない
- upsert は INSERT ... ON CONFLICT で行い、SELECT してから INSERT する二段構えを書かない
- ジョブキュー的なテーブルの取り出しは FOR UPDATE SKIP LOCKED を使う
- 複数行をロックする処理は常に同じ順序(主キー順)でロックし、デッドロックを構造的に防ぐ
- 長時間トランザクションを禁止する(ロック保持・VACUUM 阻害・レプリケーション遅延の根源)
- アプリケーションレベルの相互排他には advisory lock を使い、ダミー行のロックで代用しない
- 冪等性が必要な外部起点の操作(決済・Webhook)は idempotency key を UNIQUE 制約付きで永続化する

### マイグレーション・ゼロダウンタイム

- マイグレーションは expand → migrate → contract の3段階で行い、旧コードと新スキーマが共存できる状態を常に保つ
- カラム削除は「コードから参照を消してデプロイ → 次のリリースで DROP」の2リリースに分ける
- 大テーブルへのインデックス追加は CREATE INDEX CONCURRENTLY で行う(通常の CREATE INDEX は書き込みをブロックする)
- マイグレーション実行時は lock_timeout / statement_timeout を設定し、ロック待ちでアプリを巻き込まない
- NOT NULL 追加は「DEFAULT 付きで追加 → backfill → 制約追加」の手順を守る(PostgreSQL 11+ の DEFAULT 付き ADD COLUMN はテーブル書き換え不要)
- 既存テーブルへの CHECK / FK 制約追加は NOT VALID で追加してから VALIDATE CONSTRAINT する
- カラムの型変更・リネームは「新カラム追加 → 二重書き込み → backfill → 参照切替 → 旧カラム削除」で行い、ALTER TYPE / RENAME を本番テーブルに直接撃たない
- backfill はバッチ(1000〜10000行)+スリープで行い、単一 UPDATE 文で全行を書き換えない
- スキーマ変更とデータ移行を同一マイグレーションファイルに混ぜない
- ロールバック不能なマイグレーション(DROP、不可逆変換)は明示的にマークし、リリースノートに載せる

### クエリ・アクセスパターン

- ページネーションは OFFSET でなく keyset(seek)方式で実装する(深いページで線形に遅くなる)
- SELECT * を本番コードで使わず、必要カラムを列挙する(TOAST 読み込み・帯域・covering index 阻害)
- 集計値の非正規化(counter cache・集計テーブル)には必ず再計算ジョブによる整合性回復手段をセットで用意する
- 論理削除は安易に採用せず、採用時は `deleted_at` + partial unique index + デフォルトスコープの N+1 的漏れ対策まで含めて設計する
- 監査要件には updated_at では足りない。監査ログテーブル(誰が・何を・いつ・前後値)を別途設ける
- EAV(entity-attribute-value)パターンを採用しない(型・制約・インデックスを全て失う)
- ポリモーフィック関連は FK 制約を張れないことを理解した上で、可能なら排他的な複数 FK + CHECK で代替する
- 本番相当のデータ量で EXPLAIN (ANALYZE, BUFFERS) を確認してからクエリを採用する(開発 DB の10行では全てが速い)

---

## core: コードレビュー

- 指摘は Blocking / Should-fix / Nit の3段階重大度でラベル付けし、Nit で approve を止めない
- 全指摘に file:line を添え、該当コードを引用する
- レビュアーはコードを書き直さず、問題・理由・方向性の指摘に徹する
- 「動くか」でなく「エラーパス・境界値・並行実行・部分失敗時に何が起きるか」を確認する
- 変更されたコードパスのテスト有無を確認し、欠落は Blocking として指摘する
- diff の外を見る: 呼び出し元への影響、マイグレーションとデプロイの順序、feature flag の消し忘れ
- 差分に含まれる「ついで変更」(リファクタ混入)は分離を要求する(レビュー可能性の確保)
- セキュリティ観点(入力検証・認可・SQL/コマンドインジェクション・秘密情報のログ出力)を明示的なチェック項目にする
- 命名は「読者が実装を見ずに振る舞いを予測できるか」で判定する
- パフォーマンス指摘は推測でなく計測(クエリプラン・ベンチマーク)を求める
- レビューは「Ready to ship / Address blockers then ship / Needs another pass」の一行結論で締める
- 大きな PR は分割を要求する(400行を超えた diff の欠陥検出率は急落する)

## core: ADR・判断の資産化

- 設計判断が発生したその場で ADR に記録する(1判断 = 1ファイル、連番、statusフィールド付き)
- ADR は Context / Decision / Consequences の3部構成とし、Consequences には受け入れたデメリットを必ず書く
- 却下した代替案と却下理由を必ず併記する(将来の再提案コストを削減する)
- ADR は不変。判断を覆すときは新 ADR で supersede し、旧 ADR の status を superseded に変えるだけで本文は書き換えない
- スキル内の全ての「〜すべき」は対応する ADR へのリンクを持ち、根拠のない原則を作らない
- 「暫定対応」をコードに入れる場合、期限と解消条件を ADR か issue に残す
- 原則には適用除外条件(escape hatch)を明記し、原理主義的適用を防ぐ

---

## rails

### ActiveRecord: クエリ

- N+1 は includes / preload / eager_load を使い分けて解消する(WHERE で関連を絞るなら eager_load、それ以外は preload)
- strict_loading を新規モデルのデフォルトにし、Prosopite(または Bullet)を test / CI で例外化する
- uniqueness バリデーションには必ず対応する UNIQUE INDEX を併設する
- default_scope を使わない(unscoped 汚染・意図しない JOIN 条件・new のデフォルト値化の三重罠)
- scope は必ず lambda で定義し、nil を返しうる scope を書かない(scope はチェーン可能な relation を返す契約)
- 存在確認は present? / any?(ロード済みでない場合)でなく exists? を使う
- 件数は length(ロード済み)/ size(文脈依存)/ count(常に SQL)の違いを理解して使い分ける
- 特定カラムだけ必要なら pluck、AR オブジェクトが必要なら select を使う
- 大量レコードの走査は find_each / in_batches を使い、all.each を書かない
- or 条件は ActiveRecord の or メソッドか Arel で組み、文字列 SQL の連結をしない
- SQL に値を埋め込むときは必ずプレースホルダ(`where("x > ?", v)`)を使う
- サブクエリは relation をそのまま `where(id: subquery)` に渡し、pluck して IN に展開しない(2往復と巨大 IN 句を防ぐ)
- 共通の絞り込みは Query オブジェクトか scope に集約し、コントローラに where を散らばらせない

### モデル・アプリケーション設計

- callback から外部副作用(メール・外部 API・enqueue)を起こさない。永続化に付随する不変条件の維持のみに使う
- どうしても callback で副作用が要る場合は after_commit に限定する
- 手続き的ユースケースは PORO の Service / UseCase オブジェクトへ、フォーム固有の検証は Form オブジェクトへ抽出する
- Service オブジェクトは1公開メソッド・明示的な戻り値(Result)とし、神クラス化した Manager を作らない
- Concern は複数モデルで共有する振る舞い専用とし、単一モデルのファイル分割に使わない
- enum は文字列カラムを backing にし、`prefix: true` / `suffix: true` でメソッド名衝突を防ぐ
- STI は「振る舞いだけが異なり属性がほぼ同じ」場合に限定し、サブクラス固有カラムが増え始めたら delegated_type か別テーブルへ移行する
- ポリモーフィック関連より delegated_type を優先する(FK 制約と eager load の両立)
- validates は「ユーザー入力の検証」、DB 制約は「データ完全性の最後の砦」として必ず二重化する
- Time.now / Date.today でなく Time.current / Date.current を使う(アプリ timezone)
- update_all / delete_all / update_column が callback・validation をスキップすることを理解した箇所でのみ使う
- モデルに where 句を含むメソッドを直接生やす前に、その責務が scope / Query オブジェクトでないか検討する

### トランザクション・ジョブ

- DB トランザクション内で外部 API 呼び出し・sleep・job enqueue をしない
- job の enqueue は after_commit(または `ActiveJob::Base.enqueue_after_transaction_commit`)で行う
- ネストしたトランザクションが要求どおり動くのは `requires_new: true` + SAVEPOINT のときだけと理解する
- ActiveJob は at-least-once 配信を前提に冪等に実装する(処理済み判定 or 自然な冪等性)
- job の引数には AR オブジェクトや巨大ペイロードでなく ID などのプリミティブを渡す(GlobalID 遅延解決とキュー肥大の回避)
- job 内で対象レコードが消えている場合(discard_on ActiveRecord::RecordNotFound)を設計に含める
- retry 戦略(回数・バックオフ・dead letter)をジョブクラスごとに明示し、デフォルト任せにしない
- 定期実行ジョブは多重起動を advisory lock か uniqueness 制御で防ぐ
- キューを latency 要件で分離し(critical / default / low)、重いバッチが通知を詰まらせない構成にする
- 楽観ロック(lock_version)か with_lock(悲観)かを、更新競合の頻度で選ぶ

### マイグレーション

- strong_migrations を導入し、危険な操作(非 CONCURRENTLY のインデックス作成等)を機械的にブロックする
- schema.rb(または structure.sql)の diff をレビュー対象にする
- マイグレーションは冪等・後方互換に書き、旧バージョンのアプリが動いている間に適用できることを保証する
- データ移行(backfill)はマイグレーションでなく rake タスクか maintenance_tasks で行い、進捗・再開可能性を持たせる
- ignored_columns でカラム参照を先に切ってから DROP する

### セキュリティ

- 許可属性は params.expect(Rails 7.2+)/ strong parameters で明示し、permit! を禁止する
- 認可(Pundit / 手書き)は「全アクションで認可チェックが走ったこと」を verify_authorized 相当で機械検証する
- 秘密情報は credentials か ENV で管理し、ログへの出力は filter_parameters で機械的にマスクする
- html_safe / raw の使用をレビュー必須にし、ユーザー入力由来の文字列には絶対に適用しない
- リダイレクト先にユーザー入力を使う場合は allow list 検証する(open redirect)
- Brakeman を CI の必須ゲートにする
- send / constantize / eval にユーザー入力を渡さない
- ファイルアップロードは content-type 検証・サイズ上限・ストレージ直アップロード(署名付き URL)を基本にする

### パフォーマンス・キャッシュ

- キャッシュキーはレコードの cache_key_with_version に乗せ、手動 expire の網羅に頼らない
- 低レベルキャッシュ(Rails.cache.fetch)には expires_in と race_condition_ttl を設定する
- カウントの頻繁な表示は counter_cache を使い、リセット手段(reset_counters)を運用に組み込む
- レスポンスの重い集計はリクエスト内で計算せず、非同期集計 + 保存済みの値を返す
- rack-mini-profiler を開発環境の常設にし、遅いエンドポイントは EXPLAIN ANALYZE でプランを確認する
- Rails 8 の Solid Queue / Solid Cache / Solid Cable は「Redis 運用を消せる」利点と引き換えの DB 負荷を見積もった上で採用を判断する

### テスト

- model spec と request spec を主体にし、system spec はクリティカルフローに絞る(controller spec は書かない)
- FactoryBot の factory は最小の有効レコードを定義し、trait で変化を表現し、関連の自動生成連鎖を避ける
- create でなく build / build_stubbed で済むテストは DB を触らない
- 時刻依存のテストは travel_to / freeze_time を使い、Time.current の生比較をしない
- 外部 API は WebMock / VCR でスタブし、テストからの実ネットワークを禁止する
- let! と before の乱用でテストデータを暗黙化せず、テスト本文から前提が読めるようにする
- flaky の温床(sleep、順序依存、時刻依存、乱数)を lint とレビューで排除する
- RuboCop は共有 gem を inherit_gem で継承し、プロジェクトの .rubocop.yml には差分のみ書く。inline disable にはコメントで理由を書く

---

## typescript(VoidZero スタック)

### tsconfig・言語設定

- strict: true に加え noUncheckedIndexedAccess / noImplicitOverride / exactOptionalPropertyTypes / useUnknownInCatchVariables を有効化する
- verbatimModuleSyntax を有効化し、型のみの import は `import type` で書く
- moduleResolution は bundler(アプリ)/ node16+(公開ライブラリ)を使い分け、node10 互換の設定を残さない
- skipLibCheck: true は依存の型不整合を握りつぶす取引であることを理解して使う
- コンパイラオプションの緩和(strict の個別 off)はリポジトリ単位で禁止し、必要なら該当行の @ts-expect-error(理由コメント必須)で局所化する
- @ts-ignore を禁止し @ts-expect-error を使う(修正されたら型エラーとして検知される)

### 型設計

- any を禁止し、型不明の外部入力は unknown で受けて型ガードで絞る
- 型アサーション(as)は最終手段とし、リテラルの型付けには satisfies を優先する
- enum を使わず、as const オブジェクト + `typeof x[keyof typeof x]` または文字列リテラル union を使う
- 状態は boolean フラグの組合せでなく判別可能ユニオンで表現し、判別キーの名前(kind / type)をリポジトリで統一する
- switch の網羅性は default 節での `satisfies never`(assertNever)で保証する
- 不正な状態を型で表現不能にする(loading と data が同時に存在できる型を書かない)
- 構造的型付けで混同しうる ID・単位・通貨は branded type で区別する
- 関数の戻り値型は公開 API では明示し、内部実装では推論に任せてよい(境界で契約を固定する)
- オブジェクトは基本 readonly / ReadonlyArray で受け、ミューテーションが契約の場合のみ可変で受ける
- Pick / Omit / Partial の深いネストより、意味のある名前付き型を定義する
- ジェネリクスは制約(extends)を必ず付け、「1回しか使われない型パラメータ」は具体型に潰す
- オーバーロードより判別可能ユニオン引数を優先する(実装との乖離バグを防ぐ)
- グローバル拡張(declare global)と declaration merging を原則禁止し、使う場合は1ファイルに隔離する

### 実行時境界

- API 応答・フォーム入力・URL パラメータ・環境変数は zod / valibot で parse し、型と実行時値を一致させる(parse, don't validate)
- 環境変数はアプリ起動時に一括 parse して型付き config オブジェクトとして export し、process.env の散在参照を禁止する
- parse は信頼境界(ネットワーク・プロセス外)でのみ行い、内部の関数間で再検証しない
- スキーマから型を導出する(`z.infer`)方向に統一し、型とスキーマの二重定義をしない
- JSON の数値が i64 を超えうるフィールド(ID・金額)は文字列で受ける
- 日付は境界で ISO 8601 文字列 ⇔ Date(または Temporal)に変換し、内部表現を統一する

### 非同期・エラー

- floating promise を lint で禁止し、意図的な fire-and-forget は void 演算子 + 理由コメントで明示する
- 並行実行は Promise.all(全成功前提)と Promise.allSettled(部分失敗許容)を要件で使い分ける
- キャンセルが必要な非同期処理は AbortController / AbortSignal を貫通させる
- エラー方針を「例外」か「Result 型(neverthrow 等)」のどちらかにリポジトリで統一し、混在させない
- 独自エラーは Error を継承し、cause オプションで原因チェーンを保持する
- catch した unknown は instanceof で絞ってから扱い、`(e as Error).message` を書かない
- 深いコピーは JSON.parse(JSON.stringify()) でなく structuredClone を使う

### モジュール・パッケージ

- default export を避け named export に統一する
- barrel file(index.ts での re-export 集約)を作らない(tree-shaking 阻害・循環 import・ビルド時間悪化)
- 循環 import を lint(oxlint import/no-cycle 相当)で検出しゼロを維持する
- パッケージは ESM-only とし、exports field でエントリポイントを定義して深い import を封じる
- 公開ライブラリは isolatedDeclarations 互換に保ち、公開 API に明示的型注釈を書く(tsdown の高速 DTS 生成の前提)
- sideEffects: false を宣言できるパッケージ構造を保つ(モジュールロード時の副作用を書かない)
- 欠損値は原則 undefined に寄せ、null は「意図的な空」の表現としてスキーマ境界のみで扱う

### ツールチェーン・monorepo

- ツールチェーンは Vite+(vp)に統一し、format / lint / typecheck を vp check に集約する
- lint は Oxlint、フォーマットは Oxfmt、型検査は tsgo(tsgolint)を使い、ESLint / Prettier / tsc をホットパスから外す
- ルール共有は @org/oxlint-config を npm 配布し、各プロジェクトは extend + 差分のみ書く
- Vite+ に乗れないプロジェクトは oxlint.config.ts / oxfmt.config.ts 単体構成に落とし、共有 config は同一物を参照する
- pre-commit は staged hooks(`'*': 'vp check --fix'`)で強制し、CI で同じチェックを再実行する(hooks はバイパス可能なので CI が正)
- monorepo は pnpm workspace + catalog で依存バージョンを一元管理し、同一依存の複数バージョン混在を syncpack 等で検出する
- Node バージョンは mise / engines + packageManager field で固定する
- lockfile を必ずコミットし、CI では frozen-lockfile でインストールする
- ライブラリのバンドルは tsdown、アプリは Vite(Rolldown)を使う

---

## react

### 状態設計

- 派生値を useState + useEffect で同期せず、レンダー中に計算する(derived state is not state)
- サーバ状態(API データ)は TanStack Query 等のキャッシュ層に置き、クライアント状態(UI 状態)と明確に分離する
- グローバル状態管理を導入する前に「それはサーバ状態では?」「URL に置くべきでは?」を検討する
- 検索条件・タブ・ページなど共有可能な UI 状態は URL(search params)に置く
- 状態は使用箇所の最近傍に置き(colocation)、共有が必要になるまでリフトアップしない
- 複数フィールドが連動して変わる状態は useState の群れでなく useReducer + 判別可能ユニオンの action で管理する
- props を useState の初期値にコピーしない。prop 変化でのリセットは key による再マウントで行う
- 前回 props との比較が必要なら useEffect でなくレンダー中の「previous state パターン」で処理する
- Context には変更頻度の異なる値を同居させず、値と dispatch を別 Context に分割する
- Context は DI(テーマ・現在ユーザー・ロケール)用途とし、高頻度更新のストアとして使わない

### effect

- useEffect は「外部システムとの同期」専用とし、データ取得・イベント応答・状態変換に使わない
- ユーザー操作に起因する処理はイベントハンドラに書く(「表示されたから走る」処理だけが effect)
- effect には必ずクリーンアップを書き、購読・タイマー・AbortController の解放を対にする
- effect 内で最新値を読みたいが再実行トリガーにしたくない値は useEffectEvent で扱う
- 依存配列を黙らせるための eslint-disable を禁止し、依存が多すぎるなら effect の設計を疑う
- 外部ストアの購読は useEffect + setState でなく useSyncExternalStore を使う
- アプリ初期化(1回だけ実行)を effect + 空配列で表現せず、モジュールトップレベルか初期化関数で行う

### コンポーネント設計

- バリアントを boolean props の増殖で表現せず、children と composition(compound components)で解決する
- 制御(value + onChange)か非制御(defaultValue)かをコンポーネントごとに一貫させ、途中で切り替えない
- props は最小のインターフェースで受け(必要なプリミティブ)、巨大なドメインオブジェクトをそのまま流さない
- ロジックは custom hook に抽出し、コンポーネント本体は JSX の宣言に近づける
- React 19 では forwardRef を使わず ref を通常の prop として受ける
- レンダー内で コンポーネントを定義しない(毎レンダーで別型となり state が消える)
- key に配列 index を使わず安定 ID を使う。並べ替え・挿入があるリストでは特に厳守する
- 条件付きレンダーで `count && <X/>` を書かない(0 が描画される)。三項か Boolean 化する

### React Compiler・パフォーマンス

- React Compiler を有効化し、手動の memo / useMemo / useCallback を新規に書かない
- Rules of React(レンダー純粋性・props / state の不変性・hooks のトップレベル呼び出し)を lint で強制する(違反コンポーネントは Compiler が最適化をスキップする)
- 既存の useMemo / useCallback は Compiler 導入後も一括削除せず、テストで守られた範囲から漸進的に剥がす
- 大きなリストは仮想化(virtualization)し、DOM ノード数で殴らない
- 重い再レンダーを伴う入力には useDeferredValue / useTransition で優先度を分ける
- ルート単位の code splitting(lazy + Suspense)をデフォルトにする
- レンダー中に ref を読み書きしない(commit 後の effect かイベントハンドラで扱う)

### データ取得・非同期 UI

- fetch の手書き(useEffect + useState + loading フラグ)を書かず、Query ライブラリの宣言的キャッシュに乗せる
- query key はリソース階層の規約(['todos', { filter }] 等)で統一し、invalidation を key 前綴りで行う
- staleTime を意図して設定する(デフォルト 0 のまま全画面 refetch を放置しない)
- 依存のない複数リクエストは並列化し、コンポーネント階層による fetch waterfall を作らない(必要ならルートローダーへ hoist)
- ミューテーション成功時は「invalidate(再取得)」か「setQueryData(手動更新)」かを応答の完全性で選ぶ
- 楽観的更新は useOptimistic(または Query の onMutate + ロールバック)で行い、失敗時の巻き戻しを必ず実装する
- フォームは useActionState / form actions(または react-hook-form)を使い、全 input の手動 onChange 管理をしない
- フォームの検証スキーマ(zod)はサーバと共有し、クライアント単独の検証を信頼しない
- 非同期 UI は Suspense + ErrorBoundary の境界で宣言し、境界の粒度(ページ / セクション)を設計する
- ErrorBoundary にはリセット手段(retry)を付け、握りつぶさず監視基盤へ報告する

### a11y・セキュリティ

- semantic HTML を優先する(div + onClick でなく button、a には href)
- ARIA は semantic HTML で表現できない不足分のみ付与する(No ARIA is better than bad ARIA)
- モーダル・ドロワーはフォーカストラップ・Escape・フォーカス返却まで実装するか、実装済みのヘッドレス UI ライブラリを使う
- インタラクティブ要素はキーボードのみで完結できることをテストで保証する
- jsx-a11y 相当の lint ルールを CI で強制する
- dangerouslySetInnerHTML を禁止し、不可避ならサニタイズ関数の経由を型で強制する
- ユーザー入力を href / src に使うときは URL スキームを検証する(javascript: 対策)
- トークン等の秘密情報を localStorage に置かない。クライアントに公開してよい env 変数だけを VITE_ プレフィックスに載せる

### テスト

- Testing Library でユーザー視点のテストを書き、実装詳細(state・内部関数)をテストしない
- クエリは getByRole を最優先、次に label / text、testId は最終手段とする
- イベントは fireEvent でなく userEvent を使う
- 非同期の出現待ちは findBy / waitFor を使い、waitFor のコールバックに副作用を書かない
- ネットワークは MSW でモックし、fetch / axios のモジュールモックをしない
- コンポーネントテストは Vitest browser mode で実ブラウザ実行する
- 主要フローには axe 系の自動 a11y チェックを組み込む
- スナップショットテストは小さく意図的な範囲に限定し、巨大スナップショットの盲目 update を禁止する

---

## go

### エラー

- エラーは握りつぶさず、`fmt.Errorf("operation context: %w", err)` で文脈を付けて返す
- エラーメッセージは小文字始まり・句点なし・重複文脈なし(呼び出し側が積むので "failed to" の連鎖を作らない)
- エラー判定は errors.Is / errors.As を使い、文字列比較・型 switch をしない
- %w でラップしたエラーは公開 API の互換性契約になることを理解し、実装詳細のエラーは %v で不透明化する
- 呼び出し側が分岐すべきエラーは sentinel(errors.New)か独自型として公開 API の一部に含める
- panic はプログラミングバグ(不変条件違反)専用とし、回復可能なエラー・入力不正に使わない
- 複数エラーの集約は errors.Join を使う
- if err != nil のスコープを最小にし、`if v, err := f(); err != nil` の形で変数の生存範囲を絞る

### 並行性

- goroutine は終了経路(context cancel / channel close)を設計してから起動する(起動は1行、リークは永続)
- 並行処理の集約は errgroup(必要なら SetLimit)を使い、生の WaitGroup + channel 編みを最小化する
- 共有状態の保護はまず sync.Mutex を検討し、channel は所有権の移転とパイプラインに使う
- channel の close は送信側の責務とし、受信側で close しない
- select には context.Done() の case を含め、永久ブロックの可能性を残さない
- ミュータブルな値を goroutine にキャプチャさせるときはループ変数・共有変数のデータ競合を検査する(CI で -race を常時有効化)
- 一度きりの初期化は sync.Once、単純なフラグ・カウンタは sync/atomic を使う
- time.After をループ内で使わない(タイマーがリークする)。time.NewTimer / Ticker を再利用する

### API・パッケージ設計

- interface は提供側でなく利用側パッケージで定義し、メソッド数を最小に保つ(accept interfaces, return structs)
- 単一実装しかない interface を「テストのため」に事前定義しない(必要になった消費側で切る)
- context.Context は第一引数 ctx で受け渡し、struct フィールドに保存しない
- context.Value は request-scoped なメタデータ(trace ID 等)専用とし、関数の必須依存を流さない
- パッケージ名は小文字・単数の名詞とし、util / common / helpers / base を禁止する
- 公開識別子を最小化し、internal/ で意図しない import を防ぐ
- 依存はコンストラクタ引数で明示注入し、DI コンテナ・パッケージレベル変数・init() での登録を避ける
- 多数のオプション引数は functional options パターンか config struct で受ける
- ゼロ値がそのまま有効に使える型設計にする(useful zero value)
- 構造体の埋め込み(embedding)は「is-a 的にメソッドセットを公開したい」場合のみ使い、実装の再利用目的で乱用しない
- ジェネリクスはコンテナ・アルゴリズムの型安全化に使い、interface で足りる抽象に持ち込まない
- スライスを返す関数は「呼び出し側が所有する新しいスライス」を返し、内部バッファを共有しない(aliasing 事故)
- 時刻は time.Time / time.Duration で持ち、int の「秒数」を引き回さない

### HTTP・運用

- http.Server には ReadTimeout / WriteTimeout / IdleTimeout を必ず設定する(デフォルトは無制限)
- http.Client にも Timeout(またはリクエスト毎の context deadline)を設定し、http.DefaultClient を本番で使わない
- レスポンス Body は必ず defer Close し、再利用のため読み切ってから閉じる
- グレースフルシャットダウンは signal.NotifyContext + server.Shutdown で実装し、inflight リクエストの完了を待つ
- ログは log/slog の構造化ログに統一し、fmt.Println / log.Printf を本番コードで使わない
- 外部呼び出しには必ず deadline を設定し、リトライには指数バックオフ + ジッタを付ける
- JSON の omitempty がゼロ値(0, false, "")を落とす仕様を理解し、区別が必要なフィールドはポインタか Null 型で持つ

### テスト・ツール

- テストは table-driven で書き、t.Run でサブテスト化し、可能な限り t.Parallel を付ける
- time.Now・乱数・外部 I/O は関数値かインターフェースで注入し、テストで差し替える
- テストヘルパーには t.Helper() を付け、失敗行を呼び出し側に向ける
- 一時リソースは t.TempDir / t.Cleanup で管理する
- パーサ・エンコーダ等の入力処理には fuzz テスト(go test -fuzz)を追加する
- golangci-lint を共有設定で運用し、errcheck / govet / staticcheck を必須にする
- ツール依存は go.mod の tool ディレクティブ(Go 1.24+)で管理し、tools.go ハックをやめる
- ベンチマークは testing.B + benchstat で差分の統計的有意性を見る
- guard clause の早期 return でネストを浅く保つ(happy path を左端・最下部に揃える)

---

## rust

### エラー・パニック

- 本番コードで unwrap を使わない。不変条件が保証済みの箇所のみ expect に「なぜ成立するか」を書く
- エラーは `?` で伝播し、ライブラリは thiserror の型付き enum、アプリケーションは anyhow + .context() を使う
- ライブラリの公開エラー型は non_exhaustive を付け、バリアント追加を破壊的変更にしない
- Error トレイトの source() チェーンを維持し、原因を文字列化で潰さない
- ライブラリ内の panic しうる条件(index、除算)は消すか、ドキュメントの # Panics 節に明記する
- Result を返す関数の呼び出しで `let _ =` によるエラー破棄を禁止する(must_use を尊重する)

### 型設計

- 不正な状態を型で表現不能にする: Option の組合せ爆発は enum に、検証済みデータは newtype に落とす
- 素の u64 / String の ID・単位・通貨は newtype でラップし、取り違えをコンパイルエラーにする
- newtype には必要な trait(Debug, Clone, PartialEq, Hash, serde)を derive し、Deref による透過は実装しない
- コンストラクタで検証する型は「作れたら常に有効」(parse, don't validate)にし、内部フィールドを非公開に保つ
- match は網羅的に書き、`_` ワイルドカードアームで enum バリアント追加時のコンパイル検知を潰さない
- 状態遷移が重要なオブジェクトは typestate パターンで不正遷移を型エラーにする
- 複雑な構築は builder パターン(derive_builder / bon)で必須・任意を型で区別する
- bool 引数が2つ以上並ぶ関数は enum 引数に置き換える

### 所有権・API 設計

- 関数引数は借用(&str / &[T] / impl AsRef)で受け、所有権(String / Vec)は保持する場合のみ受け取る
- 戻り値は所有型を返し、ライフタイム付き参照返しは iterator・view 型に限定する
- borrow checker からの逃げとして clone を乱用せず、共有が本質なら Rc / Arc を意図して選ぶ
- 条件次第で所有 / 借用が変わる戻り値は Cow で表現する
- 公開 API は Rust API Guidelines に準拠する(C-CONV: as_/to_/into_ の使い分け、C-GETTER: get_ プレフィックスなし)
- From / TryFrom を実装して変換を標準化し、独自の convert メソッドを乱造しない
- トレイト境界は struct 定義でなく impl / 関数側に書く
- 外部に実装させたくないトレイトは sealed trait パターンで封じる
- 静的ディスパッチ(ジェネリクス)を基本とし、dyn Trait は型消去が本質的に必要な箇所(ヘテロなコレクション・プラグイン)に限定する
- 公開型の semver 影響は cargo-semver-checks を CI に入れて機械検証する
- feature flag は加法的(additive)に設計し、相互排他な feature を作らない

### async

- async ランタイムは tokio に統一し、ランタイム非依存が必要なライブラリのみ抽象化を検討する
- async 関数内でブロッキング I/O・重い CPU 処理を直接実行せず、spawn_blocking / rayon に逃がす
- .await を跨いで MutexGuard(std::sync::Mutex)を保持しない(tokio::sync::Mutex か設計変更)
- tokio::select! を使うブランチの future はキャンセル安全性(cancellation safety)を確認する
- spawn した JoinHandle を放置せず、エラー伝播か detach の意図を明示する
- ストリーム処理のバックプレッシャーを設計し、無制限バッファの channel を使わない

### unsafe・依存・CI

- unsafe は最小のモジュールに隔離し、各ブロックに `// SAFETY:` で成立条件を記述する
- unsafe を含むコードは Miri を CI で回す
- clippy は `-D warnings` で運用し、pedantic は個別 allow(理由コメント付き)で選択的に採用する
- cargo fmt / clippy / test / doc を CI 必須とし、doctest で公開 API の例をコンパイル保証する
- 依存は cargo-deny(licenses / bans / advisories / sources)を CI で回す
- rust-version(MSRV)を Cargo.toml に宣言し、CI で MSRV ビルドを検証する
- クレートが育ったら workspace 分割し、workspace.dependencies でバージョンを一元管理する
- serde の構造体には deny_unknown_fields の要否・rename_all 規約をリポジトリで統一する
- テストは cargo-nextest で実行し、性質ベースの検証には proptest を使う
- 手書き index ループよりイテレータチェーンを優先し、Result の集約は `collect::<Result<Vec<_>, _>>()` を使う

---

## terraform

### state・構成

- state はリモートバックエンドに置き、ロックと保存時暗号化を必須にする
- state を手で編集しない。操作は terraform state コマンドと moved / removed / import ブロックに限定する
- 環境分離は workspace でなくディレクトリ(またはリポジトリ)分離で行い、環境差分は tfvars に閉じ込める
- state の分割単位は「変更頻度と影響範囲」(network / data / app 等)で切り、単一巨大 state を作らない
- state 間の参照は terraform_remote_state より明示的な data source(タグ・名前による検索)を優先する(密結合の緩和)

### module 設計

- module は「共に変更されるリソース群」単位で薄く作り、ルートモジュールで合成する
- 単一リソースの薄いラッパー module を作らない
- module は semver でタグ付けし、参照側は version 制約(source + ref)でピン留めする
- module 内にプロバイダ設定(provider block)を書かず、呼び出し側から注入する
- variable には type と description を必須とし、制約は validation ブロックで、非 null 保証は nullable = false で表現する
- 秘密になりうる variable / output には sensitive = true を付ける
- output にも description を付け、module の公開契約として扱う
- リソースの前提・事後条件は precondition / postcondition ブロックで表明する

### 言語・スタイル

- count でなく for_each を使う(要素の並び替えによる意図しない再作成を防ぐ)
- for_each のキーには変化しない自然キーを使い、インデックスや変わりうる名前を使わない
- 命名は snake_case、種別内で唯一のリソースは `this` と命名する
- リソースの移動・改名は moved ブロック、管理からの除外は removed ブロック、取り込みは import ブロックで宣言的に行う
- dynamic ブロックは可読性を落とすため、可変構造が本質的な場合のみ使う
- depends_on は暗黙依存(参照)で表現できない場合の最終手段とし、使用時は理由をコメントする
- 条件分岐の三項演算子をネストさせず、locals で名前を付けて分解する
- null_resource / local-exec は「プロバイダが存在しない操作」の最終手段とし、恒常運用に組み込まない

### セキュリティ・秘密情報

- 秘密情報は state に平文で載る前提で設計し、値は SSM / Secrets Manager 参照か ephemeral values(1.10+)で扱う
- ハードコードされた ARN / アカウント ID / AMI ID を避け、data source と変数で解決する
- IAM ポリシーはワイルドカード(Action: "*", Resource: "*")を lint で禁止し、最小権限で書く
- provider の default_tags で管理主体・環境・コストセンターのタグ付けを強制する
- 適用に使う credential は環境ごとに分離し、CI の OIDC 連携で長期キーを排除する

### CI/CD・運用

- terraform fmt -check / validate / tflint / trivy を CI の必須ゲートにする
- ポリシー検証(OPA / conftest / Sentinel)で組織ルール(リージョン制限・必須タグ・禁止リソース)を機械化する
- required_providers と required_version を明示し、.terraform.lock.hcl をコミットする
- plan と apply をパイプラインで分離し、apply は plan 時に保存した plan ファイル(-out)を入力にする(TOCTOU 排除)
- plan 差分を PR に自動コメントし、人間の approve なしに apply しない
- 定期的な drift 検知(スケジュール plan)を仕込み、手動変更を検出したら是正かコード化する
- 消失が致命的なリソース(DB・KMS キー)には lifecycle prevent_destroy を付ける
- コスト影響は infracost 等で PR 時に可視化する

---

## prompt engineering

### 指示の書き方

- 指示は明確・直接に書き、「適切に」「いい感じに」等の曖昧語を成功条件の明示に置き換える
- 対象読者・利用文脈をプロンプトに含める(「新しく入ったチームメンバーに説明するように」)
- 禁止事項の列挙より「何をすべきか」の肯定形で指示する
- 数値制約は厳密に書く(「簡潔に」でなく「3文以内」)。ただし不要な硬さを生むので本当に必要なときのみ
- モデルが既に知っている一般知識をプロンプトで再説明しない(コンテキストは有限資源)
- 指示同士の矛盾を定期監査する(矛盾した指示は末尾優先などの未定義動作を生む)
- ペルソナ指定は出力の語彙・観点を変える目的で使い、能力向上の呪文として乱用しない

### 構造・few-shot

- 指示・データ・例は XML タグ(<instructions> / <context> / <example>)で構造的に区切り、混在させない
- few-shot 例は多様で正準的(canonical)なものを少数厳選する。エッジケースの羅列で置き換えない
- 例には正例だけでなく「よくある間違いと、なぜ間違いか」の負例を含める
- 望ましい出力の形式は散文で説明せずスキーマまたは出力例そのもので示す
- テンプレート変数は明示的なデリミタで囲い、ユーザー入力と指示を構造的に分離する
- 役割・トーン・不変ルールは system prompt、タスク固有の指示・データは user message に置く

### 長文コンテキスト・grounding

- 長文ドキュメントは先頭、指示は末尾に配置する
- 複数ドキュメントは <document> タグ + source / index メタデータ付きで構造化する
- 結論の前に該当箇所の引用・抽出をさせてから回答させる(grounding、幻覚抑制)
- 「情報がなければ『わからない』と答える」許可を明示し、埋め合わせ生成を防ぐ
- 検索・RAG の結果は「信頼できないデータ」として扱う指示を添え、結果内の指示文への追従(indirect prompt injection)を禁じる

### 推論・出力制御

- 多段推論が必要なタスクは extended thinking を使い、単純な分類・抽出には使わない(コストとレイテンシ)
- thinking を使わない場合の CoT は「考える手順」を具体的に指定する(「ステップバイステップ」より効く)
- 構造化出力が必須の場面は tool use(スキーマ強制)を使い、「JSON で答えて」の散文指示に頼らない
- API では assistant turn の prefill で出力の開始を固定できる(形式強制・前置き排除)
- 分類・抽出は temperature 低、発想・生成は高、とタスク種別ごとに固定し、temperature と top_p を同時にいじらない
- 複雑なタスクは1プロンプトに詰めず、検証可能な中間出力を挟むプロンプトチェーンに分解する

### 運用・eval

- プロンプトはコードと同様にバージョン管理し、本番プロンプトの直接編集を禁止する
- プロンプト変更は必ず eval の回帰で検証する(eval なしの「良くなった気がする」変更を禁止)
- eval は「コード採点(完全一致・パターン)/ LLM-as-judge(ルーブリック付き)/ 人間採点」を割合設計し、judge 自体も検証する
- eval セットには本番の失敗事例を還流させ、合成データだけで構成しない
- prompt caching を前提に、安定部分(system・ツール定義・文書)を先頭に、可変部分を末尾に配置してキャッシュ効率を設計する
- 出力のばらつきを見るため、重要タスクは同一入力で複数回サンプリングして評価する(pass@k / 一貫性)
- モデルバージョンの更新はピン留め + eval 通過後の切替とし、自動追従させない

---

## harness engineering

### コンテキスト管理

- コンテキストを有限の attention budget として扱い、載せる情報はトークンの限界効用で選ぶ(context rot: 長いほど個々の情報の想起精度は落ちる)
- system prompt は「適切な高度」で書く: 分岐を全列挙する brittle なハードコードでも、曖昧な高レベル指示でもない中間
- 知識は事前の全量注入でなく just-in-time retrieval(パス・検索・grep による必要時取得)を基本にする
- 事前計算した要約・インデックスと just-in-time 取得のハイブリッドを、レイテンシ要件で配合する
- 巨大なツール結果はそのまま文脈に残さず、参照(ファイルパス・ID)化して必要時に再取得できる形にする
- コンテキスト逼迫時の選択肢は compaction(要約して新ウィンドウへ)・構造化メモ(NOTES.md 等への外部化)・サブエージェント分割の3つで、タスク特性で使い分ける
- compaction ではツール結果の生データを最初に落とし、判断・決定事項・未解決項目を優先して残す
- 最新モデルではcompactionより「新規ウィンドウ + ファイルシステムからの状態再発見」を先に検討する

### ツール設計

- ツールセットは最小に保ち、人間がどちらを使うか即答できない機能重複ツールを置かない
- ツールの description には目的・入出力・使用条件・使わない条件を書く(プロンプト本文と同格のエンジニアリング対象)
- ツールは「ワークフローを完結できる」単位で設計し、細粒度 API の1:1 ラッパーを並べない
- 大量データを返しうるツールには pagination / filtering / truncation と応答トークン上限(目安 25k tokens)を実装する
- truncation 時は「絞り込んで再検索せよ」等の次アクションをレスポンスに含める(actionable error / actionable truncation)
- エラーメッセージはスタックトレースでなく「何が悪く、どう直すか」を返す
- パラメータ名・フォーマットは曖昧さを排除する(user でなく user_id、日付は ISO 8601 と明記)
- ツール数が増えたら全定義の常時ロードをやめ、検索による動的ロード(tool search / progressive disclosure)に切り替える
- 大量の中間データが流れるワークフローは、逐次ツール呼び出しでなく code execution パターン(MCP をコード API として呼ぶ)で中間結果をモデル外に保つ
- 機微データはモデルを経由させずツール間で直接受け渡す(tokenize / 参照渡し)設計を選べるようにする

### スキル・知識資産

- スキルの発火は name + description が全て: 「何をするか + いつ使うか + トリガー語」を書き、undertrigger 傾向に合わせやや強めに書く
- description には「いつ使わないか」も書き、複数スキル同時発火環境での誤発火を抑える
- SKILL.md 本文は500行以内に保ち、詳細は references/ に分離して progressive disclosure に従う
- 300行を超える参照ファイルには目次を付け、部分読み込みを可能にする
- 決定論的に実行できる処理は LLM に判断させずスクリプト化してスキルに同梱する(判断は LLM、検査・変換はコード)
- 同一の原則を複数スキルにコピーしない。スタック非依存の思想は core に置き、各スキルは実装差分だけ持つ
- AGENTS.md / CLAUDE.md は簡潔な目次 + 絶対規則に絞り、詳細はスキルへの段階開示に委ねる
- CLAUDE.md・スキルはコードと同じレビュー・バージョン管理・変更履歴の対象にする(stale な指示は害)
- 同じ説明を2回したらスキル化、同じ事故が2回起きたら lint / hook 化する(判断の資産化パイプライン)

### 強制・安全

- 破壊的操作(force push / rm -rf / DROP / 本番デプロイ)は hooks・permission 設定で機械的にブロックし、プロンプトの注意書きに頼らない
- エージェントに読ませないファイル(.env・秘密鍵・顧客データ)は deny 設定で機械的に遮断する
- サンドボックス(コンテナ・ネットワーク egress 制限)を前提とし、エージェントの実行環境と人間の環境を分離する
- 取得したWebページ・ドキュメント内の指示には従わない方針を system prompt に明記する(indirect prompt injection)
- エージェントの git 操作は専用ブランチ / worktree に隔離し、main への直接操作を禁止する
- 自動化度は「提案 → 承認付き実行 → 自動実行」の段階で上げ、eval の成績が根拠になったものだけ昇格させる

### フィードバックループ・長期タスク

- lint・型検査・テストの高速なフィードバックループを整備する(エージェントの実効性能は検証手段の質で決まる)
- エージェント自身がテスト・lint を実行して自己検証できる環境(init スクリプト・コマンドの発見可能性)を用意する
- 長時間タスクは初期化エージェントに要件リスト(全項目 failing 起点)・テスト・進捗ファイルを整備させ、後続コンテキストがファイルシステムから状態復元できるようにする
- 進捗・決定・未解決事項は構造化ファイル(JSON の状態 + テキストのメモ)に外部化し、コンテキストウィンドウを跨いで持ち越す
- サブエージェントには探索・調査を委譲し、親には蒸留済みの結果だけを返す(コンテキスト分離が目的、擬人化した役割分担が目的ではない)
- サブエージェントの応答形式・報告粒度を明示的に指定する(自由記述の報告はコンテキストを汚す)
- 探索・検索など軽いサブタスクには安価なモデルを割り当て、コストとレイテンシを設計する

### 評価・観測

- ハーネスの変更(スキル・プロンプト・ツール・hooks)は eval のタスク成功率とスキル発火率の回帰で検証する
- eval は簡単すぎるタスクで測らない(スキルは自力で解けないタスクでしか発火しない)
- エージェントのトランスクリプトを保存・監査し、失敗事例を eval とスキルに還流させる(transcript mining)
- ツールの呼び出し回数・トークン消費・失敗率をツール別に計測し、肥大・重複ツールの整理に使う
- 「エージェントが読んで直せる」ことを前提に、エラーログ・CI 出力の可読性自体を改善対象にする
- ハーネス改善にエージェント自身を使う(失敗トランスクリプトを見せて description・ツールの改善案を出させる)
