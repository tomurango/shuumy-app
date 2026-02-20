#!/bin/bash
# サンプルデータをシミュレーターに配置するスクリプト
# 使用方法:
#   ./scripts/setup_sample_data.sh               # 起動中の最初のシミュレーターを使用
#   ./scripts/setup_sample_data.sh <DEVICE_UDID>  # UDIDを指定して実行

set -e

# シミュレーターとアプリ情報
APP_ID="com.tomurango.shuumy"

# 引数でUDIDが指定されていればそれを使用、なければ起動中の最初のシミュレーターを使用
if [ -n "$1" ]; then
    DEVICE_ID="$1"
else
    DEVICE_ID=$(xcrun simctl list devices booted -j | grep -o '"udid" : "[^"]*"' | head -1 | cut -d'"' -f4)
fi

if [ -z "$DEVICE_ID" ]; then
    echo "Error: No booted simulator found"
    exit 1
fi

echo "Using simulator: $DEVICE_ID"

# アプリのデータコンテナを取得
APP_DATA=$(xcrun simctl get_app_container "$DEVICE_ID" "$APP_ID" data 2>/dev/null)/Documents

if [ -z "$APP_DATA" ] || [ "$APP_DATA" == "/Documents" ]; then
    echo "Error: App not installed. Run 'flutter install' first."
    exit 1
fi

echo "App data directory: $APP_DATA"

# imagesディレクトリを作成
mkdir -p "$APP_DATA/images"

# Lorem Picsumからサンプル画像をダウンロード
echo "Downloading sample images..."
curl -sL "https://picsum.photos/seed/reading/400/400" -o "$APP_DATA/images/hobby_reading.jpg"
curl -sL "https://picsum.photos/seed/cafe/400/400" -o "$APP_DATA/images/hobby_cafe.jpg"
curl -sL "https://picsum.photos/seed/coding/400/400" -o "$APP_DATA/images/hobby_programming.jpg"
curl -sL "https://picsum.photos/seed/music/400/400" -o "$APP_DATA/images/hobby_music.jpg"

# categories.json
echo "Creating sample data..."
cat > "$APP_DATA/categories.json" << 'EOF'
[{"id":"default_all","name":"すべて","order":0,"backgroundImagePath":null,"createdAt":"2026-02-19T12:00:00.000000","updatedAt":"2026-02-19T12:00:00.000000"}]
EOF

# hobbies.json（階層構造付き）
cat > "$APP_DATA/hobbies.json" << 'EOF'
[
  {"id":"hobby-001","title":"読書","memo":null,"imageFileName":"hobby_reading.jpg","categoryId":"default_all","order":0,"createdAt":"2026-01-15T10:00:00.000000","updatedAt":"2026-01-15T10:00:00.000000","children":[
    {"id":"node-001","title":"小説","description":"フィクション作品","order":0,"children":[
      {"id":"node-001-1","title":"村上春樹","description":null,"order":0,"children":[],"createdAt":"2026-02-01T10:00:00.000000","updatedAt":null},
      {"id":"node-001-2","title":"東野圭吾","description":null,"order":1,"children":[],"createdAt":"2026-02-01T10:00:00.000000","updatedAt":null}
    ],"createdAt":"2026-02-01T10:00:00.000000","updatedAt":null},
    {"id":"node-002","title":"技術書","description":"プログラミング関連","order":1,"children":[],"createdAt":"2026-02-01T10:00:00.000000","updatedAt":null}
  ]},
  {"id":"hobby-002","title":"カフェ巡り","memo":null,"imageFileName":"hobby_cafe.jpg","categoryId":"default_all","order":1,"createdAt":"2026-01-20T14:30:00.000000","updatedAt":"2026-01-20T14:30:00.000000","children":[
    {"id":"node-003","title":"東京","description":null,"order":0,"children":[
      {"id":"node-003-1","title":"渋谷エリア","description":null,"order":0,"children":[],"createdAt":"2026-02-01T10:00:00.000000","updatedAt":null}
    ],"createdAt":"2026-02-01T10:00:00.000000","updatedAt":null}
  ]},
  {"id":"hobby-003","title":"プログラミング","memo":null,"imageFileName":"hobby_programming.jpg","categoryId":"default_all","order":2,"createdAt":"2026-02-01T09:00:00.000000","updatedAt":"2026-02-01T09:00:00.000000","children":[
    {"id":"node-004","title":"Flutter","description":"クロスプラットフォーム開発","order":0,"children":[],"createdAt":"2026-02-01T10:00:00.000000","updatedAt":null}
  ]},
  {"id":"hobby-004","title":"音楽鑑賞","memo":null,"imageFileName":"hobby_music.jpg","categoryId":"default_all","order":3,"createdAt":"2026-02-10T18:00:00.000000","updatedAt":"2026-02-10T18:00:00.000000","children":[]}
]
EOF

# memos.json
cat > "$APP_DATA/memos.json" << 'EOF'
[
  {"id":"memo-001","hobbyId":"hobby-001","content":"今日は村上春樹の新作を読み始めた。とても引き込まれる内容。","createdAt":"2026-02-15T21:00:00.000000","updatedAt":null,"imageFileName":null,"isPinned":true,"nodeId":null},
  {"id":"memo-002","hobbyId":"hobby-002","content":"新しく見つけたカフェのラテアートが素晴らしかった！","createdAt":"2026-02-18T15:30:00.000000","updatedAt":null,"imageFileName":null,"isPinned":false,"nodeId":null}
]
EOF

# migration_status.json
cat > "$APP_DATA/migration_status.json" << 'EOF'
{"hasCompletedInitialMigration":true}
EOF

echo "Sample data setup completed!"
echo "Files created:"
ls -la "$APP_DATA/"
