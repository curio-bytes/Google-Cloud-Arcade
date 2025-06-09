#!/bin/bash
set -euo pipefail

prompt_continue() {
  echo ""
  read -p "➡️  Please check the progress for Task $1 in Qwiklabs. Press 'Y' to continue: " confirm
  if [[ "$confirm" != "Y" && "$confirm" != "y" ]]; then
    echo "❌ Script exited by user."
    exit 1
  fi
}

echo "============================================"
echo "🔁 [Task 1] Cloning the RediSearch repository"
echo "============================================"
git clone https://github.com/RediSearch/redisearch-getting-started.git
echo "✅ Cloned successfully."
prompt_continue 1

echo "=============================================================="
echo "🐳 [Task 2] Install and run a Redis instance with RediSearch using Docker"
echo "=============================================================="
docker run -d --name redis-stack-server -p 6379:6379 redis/redis-stack-server:6.2.6-v10
sleep 5
echo "✅ Redis Stack is running."
prompt_continue 2

echo "==================================="
echo "📥 [Task 3] Insert data and create index"
echo "==================================="
sudo apt-get update -y && sudo apt-get install -y redis-tools

redis-cli <<EOF
HSET movie:11002 title "Star Wars: Episode V - The Empire Strikes Back" plot "..." release_year 1980 genre "Action" rating 8.7 votes 1127635 imdb_id tt0080684
HSET movie:11003 title "The Godfather" plot "..." release_year 1972 genre "Drama" rating 9.2 votes 1563839 imdb_id tt0068646
HSET movie:11004 title "Heat" plot "..." release_year 1995 genre "Thriller" rating 8.2 votes 559490 imdb_id tt0113277
HSET movie:11005 title "Star Wars: Episode VI - Return of the Jedi" plot "..." release_year 1983 genre "Action" rating 8.3 votes 906260 imdb_id tt0086190

FT.CREATE idx:movie ON hash PREFIX 1 "movie:" SCHEMA title TEXT SORTABLE release_year NUMERIC SORTABLE rating NUMERIC SORTABLE genre TAG SORTABLE
EOF

echo "✅ Sample data inserted and index created."
prompt_continue 3

echo "==================================================="
echo "📝 [Task 4] Insert new documents and update old ones"
echo "==================================================="

redis-cli <<EOF
HSET movie:11033 title "Tomorrow Never Dies" plot "..." release_year 1997 genre "Action" rating 6.5 votes 177732 imdb_id tt0120347
HSET movie:11033 title "Tomorrow Never Dies - 007"
EXPIRE movie:11033 10
EOF

echo "⏳ Waiting 11 seconds for expiration to complete..."
sleep 11

redis-cli FT.SEARCH idx:movie "007"
echo "✅ Document insert/update/expire completed."
prompt_continue 4

echo "===================================================="
echo "📦 [Task 5] Import existing datasets (movies, theaters, users)"
echo "===================================================="
cd redisearch-getting-started/sample-app/redisearch-docker/dataset

cat import_movies.redis | redis-cli
cat import_theaters.redis | redis-cli
cat import_users.redis | redis-cli

echo "✅ Imported datasets."
prompt_continue 5

echo "======================================================="
echo "🎭 [Task 6] Create a drama movie index using FILTER expression"
echo "======================================================="

redis-cli <<EOF
FT.CREATE idx:drama ON hash PREFIX 1 "movie:" FILTER "@genre=='Drama' && @release_year>=1990 && @release_year<2000" SCHEMA title TEXT SORTABLE release_year NUMERIC SORTABLE
FT.SEARCH idx:drama "@release_year:[1990 (2000]" LIMIT 0 0
EOF

echo "✅ Drama index created."
prompt_continue 6

echo "🎉 ALL LAB TASKS COMPLETED SUCCESSFULLY!"
