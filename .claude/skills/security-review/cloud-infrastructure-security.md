| name | description |
|------|-------------|
| cloud-infrastructure-security | クラウドプラットフォームへのデプロイ、インフラストラクチャの設定、IAM ポリシーの管理、ロギング/モニタリングのセットアップ、CI/CD パイプラインの実装時に使用するスキル。ベストプラクティスに準拠したクラウドセキュリティチェックリストを提供します。 |

# クラウド & インフラストラクチャセキュリティスキル

このスキルは、クラウドインフラストラクチャ、CI/CD パイプライン、デプロイメント設定がセキュリティベストプラクティスに従い、業界標準に準拠することを保証します。

## 起動条件

- クラウドプラットフォーム（AWS、Vercel、Railway、Cloudflare）へのアプリケーションデプロイ
- IAM ロールと権限の設定
- CI/CD パイプラインのセットアップ
- Infrastructure as Code（Terraform、CloudFormation）の実装
- ロギングとモニタリングの設定
- クラウド環境でのシークレット管理
- CDN とエッジセキュリティのセットアップ
- 災害復旧とバックアップ戦略の実装

## クラウドセキュリティチェックリスト

### 1. IAM & アクセス制御

#### 最小権限の原則

```yaml
# PASS: 正しい: 最小限の権限
iam_role:
  permissions:
    - s3:GetObject  # 読み取りアクセスのみ
    - s3:ListBucket
  resources:
    - arn:aws:s3:::my-bucket/*  # 特定のバケットのみ

# FAIL: 誤り: 過度に広い権限
iam_role:
  permissions:
    - s3:*  # すべての S3 アクション
  resources:
    - "*"  # すべてのリソース
```

#### 多要素認証（MFA）

```bash
# root/管理者アカウントには常に MFA を有効にする
aws iam enable-mfa-device \
  --user-name admin \
  --serial-number arn:aws:iam::123456789:mfa/admin \
  --authentication-code1 123456 \
  --authentication-code2 789012
```

#### 検証ステップ

- [ ] 本番環境で root アカウントを使用していない
- [ ] すべての特権アカウントで MFA が有効
- [ ] サービスアカウントは長期間の認証情報ではなくロールを使用
- [ ] IAM ポリシーが最小権限に従っている
- [ ] 定期的なアクセスレビューを実施
- [ ] 未使用の認証情報をローテーションまたは削除

### 2. シークレット管理

#### クラウドシークレットマネージャー

```typescript
// PASS: 正しい: クラウドシークレットマネージャーを使用
import { SecretsManager } from '@aws-sdk/client-secrets-manager';

const client = new SecretsManager({ region: 'us-east-1' });
const secret = await client.getSecretValue({ SecretId: 'prod/api-key' });
const apiKey = JSON.parse(secret.SecretString).key;

// FAIL: 誤り: ハードコードまたは環境変数のみ
const apiKey = process.env.API_KEY; // ローテーションされず、監査されない
```

#### シークレットローテーション

```bash
# データベース認証情報の自動ローテーションを設定
aws secretsmanager rotate-secret \
  --secret-id prod/db-password \
  --rotation-lambda-arn arn:aws:lambda:region:account:function:rotate \
  --rotation-rules AutomaticallyAfterDays=30
```

#### 検証ステップ

- [ ] すべてのシークレットがクラウドシークレットマネージャー（AWS Secrets Manager、Vercel Secrets）に保存
- [ ] データベース認証情報の自動ローテーションが有効
- [ ] API キーを少なくとも四半期ごとにローテーション
- [ ] コード、ログ、エラーメッセージにシークレットがない
- [ ] シークレットアクセスの監査ログが有効

### 3. ネットワークセキュリティ

#### VPC とファイアウォール設定

```terraform
# PASS: 正しい: 制限されたセキュリティグループ
resource "aws_security_group" "app" {
  name = "app-sg"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # 内部 VPC のみ
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # HTTPS アウトバウンドのみ
  }
}

# FAIL: 誤り: インターネットに開放
resource "aws_security_group" "bad" {
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 全ポート、全IP！
  }
}
```

#### 検証ステップ

- [ ] データベースがパブリックアクセスでない
- [ ] SSH/RDP ポートが VPN/踏み台サーバーのみに制限
- [ ] セキュリティグループが最小権限に従っている
- [ ] ネットワーク ACL が設定済み
- [ ] VPC フローログが有効

### 4. ロギング & モニタリング

#### CloudWatch/ロギング設定

```typescript
// PASS: 正しい: 包括的なロギング
import { CloudWatchLogsClient, CreateLogStreamCommand } from '@aws-sdk/client-cloudwatch-logs';

const logSecurityEvent = async (event: SecurityEvent) => {
  await cloudwatch.putLogEvents({
    logGroupName: '/aws/security/events',
    logStreamName: 'authentication',
    logEvents: [{
      timestamp: Date.now(),
      message: JSON.stringify({
        type: event.type,
        userId: event.userId,
        ip: event.ip,
        result: event.result,
        // 機密データは決してログに記録しない
      })
    }]
  });
};
```

#### 検証ステップ

- [ ] すべてのサービスで CloudWatch/ロギングが有効
- [ ] 認証失敗がログに記録
- [ ] 管理者アクションが監査対象
- [ ] ログ保持が設定済み（コンプライアンスのため 90 日以上）
- [ ] 不審なアクティビティに対するアラートが設定済み
- [ ] ログが集中管理され改ざん防止

### 5. CI/CD パイプラインセキュリティ

#### セキュアなパイプライン設定

```yaml
# PASS: 正しい: セキュアな GitHub Actions ワークフロー
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read  # 最小限の権限

    steps:
      - uses: actions/checkout@v4

      # シークレットスキャン
      - name: Secret scanning
        uses: trufflesecurity/trufflehog@main

      # 依存関係の監査
      - name: Audit dependencies
        run: npm audit --audit-level=high

      # 長期間のトークンではなく OIDC を使用
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/GitHubActionsRole
          aws-region: us-east-1
```

#### サプライチェーンセキュリティ

```json
// package.json - ロックファイルと整合性チェックを使用
{
  "scripts": {
    "install": "npm ci",  // 再現可能なビルドのために ci を使用
    "audit": "npm audit --audit-level=moderate",
    "check": "npm outdated"
  }
}
```

#### 検証ステップ

- [ ] 長期間の認証情報の代わりに OIDC を使用
- [ ] パイプラインでシークレットスキャンを実施
- [ ] 依存関係の脆弱性スキャンを実施
- [ ] コンテナイメージスキャン（該当する場合）
- [ ] ブランチ保護ルールが適用
- [ ] マージ前にコードレビューが必須
- [ ] 署名付きコミットが強制

### 6. Cloudflare & CDN セキュリティ

#### Cloudflare セキュリティ設定

```typescript
// PASS: 正しい: セキュリティヘッダー付き Cloudflare Workers
export default {
  async fetch(request: Request): Promise<Response> {
    const response = await fetch(request);

    // セキュリティヘッダーを追加
    const headers = new Headers(response.headers);
    headers.set('X-Frame-Options', 'DENY');
    headers.set('X-Content-Type-Options', 'nosniff');
    headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
    headers.set('Permissions-Policy', 'geolocation=(), microphone=()');

    return new Response(response.body, {
      status: response.status,
      headers
    });
  }
};
```

#### WAF ルール

```bash
# Cloudflare WAF マネージドルールを有効化
# - OWASP Core Ruleset
# - Cloudflare Managed Ruleset
# - レート制限ルール
# - ボット保護
```

#### 検証ステップ

- [ ] OWASP ルール付き WAF が有効
- [ ] レート制限が設定済み
- [ ] ボット保護がアクティブ
- [ ] DDoS 防御が有効
- [ ] セキュリティヘッダーが設定済み
- [ ] SSL/TLS ストリクトモードが有効

### 7. バックアップ & 災害復旧

#### 自動バックアップ

```terraform
# PASS: 正しい: 自動 RDS バックアップ
resource "aws_db_instance" "main" {
  allocated_storage     = 20
  engine               = "postgres"

  backup_retention_period = 30  # 30 日間保持
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  enabled_cloudwatch_logs_exports = ["postgresql"]

  deletion_protection = true  # 誤った削除を防止
}
```

#### 検証ステップ

- [ ] 自動日次バックアップが設定済み
- [ ] バックアップ保持がコンプライアンス要件を満たす
- [ ] ポイントインタイムリカバリが有効
- [ ] バックアップテストを四半期ごとに実施
- [ ] 災害復旧計画が文書化
- [ ] RPO と RTO が定義され、テスト済み

## デプロイ前クラウドセキュリティチェックリスト

本番クラウドデプロイの前に必ず確認：

- [ ] **IAM**: root アカウント未使用、MFA 有効、最小権限ポリシー
- [ ] **シークレット**: すべてのシークレットがクラウドシークレットマネージャーにありローテーション有効
- [ ] **ネットワーク**: セキュリティグループが制限済み、パブリックデータベースなし
- [ ] **ロギング**: CloudWatch/ロギングが有効で保持設定済み
- [ ] **モニタリング**: 異常に対するアラートが設定済み
- [ ] **CI/CD**: OIDC 認証、シークレットスキャン、依存関係監査
- [ ] **CDN/WAF**: OWASP ルール付き Cloudflare WAF が有効
- [ ] **暗号化**: 保存時と転送時のデータが暗号化
- [ ] **バックアップ**: テスト済みリカバリ付き自動バックアップ
- [ ] **コンプライアンス**: GDPR/HIPAA 要件を満たす（該当する場合）
- [ ] **ドキュメント**: インフラストラクチャが文書化、ランブックが作成済み
- [ ] **インシデント対応**: セキュリティインシデント計画が策定済み

## 一般的なクラウドセキュリティ設定ミス

### S3 バケットの公開

```bash
# FAIL: 誤り: パブリックバケット
aws s3api put-bucket-acl --bucket my-bucket --acl public-read

# PASS: 正しい: 特定のアクセス付きプライベートバケット
aws s3api put-bucket-acl --bucket my-bucket --acl private
aws s3api put-bucket-policy --bucket my-bucket --policy file://policy.json
```

### RDS パブリックアクセス

```terraform
# FAIL: 誤り
resource "aws_db_instance" "bad" {
  publicly_accessible = true  # 絶対にしないこと！
}

# PASS: 正しい
resource "aws_db_instance" "good" {
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.db.id]
}
```

## リソース

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [Cloudflare Security Documentation](https://developers.cloudflare.com/security/)
- [OWASP Cloud Security](https://owasp.org/www-project-cloud-security/)
- [Terraform Security Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)

**覚えておくこと**: クラウドの設定ミスはデータ漏洩の主要な原因です。一つの公開された S3 バケットや過度に許可された IAM ポリシーがインフラストラクチャ全体を危険にさらす可能性があります。常に最小権限の原則と多層防御に従ってください。
