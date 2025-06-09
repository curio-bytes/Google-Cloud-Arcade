#!/bin/bash
set -euo pipefail




echo "[1/8] 🐳 Starting Redis Stack with RediSearch..."
docker run -d --name redis-stack-server -p 6379:6379 redis/redis-stack-server:6.2.6-v10
sleep 5

echo "[2/8] 🧪 Installing redis-tools (redis-cli)..."
sudo apt-get update -y && sudo apt-get install -y redis-tools git

echo "[3/8] 📦 Cloning the RediSearch lab repo..."
git clone https://github.com/RediSearch/redisearch-getting-started.git
cd redisearch-getting-started/sample-app/redisearch-docker/dataset

echo "[4/8] ⏫ Importing datasets (movies, theaters, users)..."
cat import_movies.redis | redis-cli
cat import_theaters.redis | redis-cli
cat import_users.redis | redis-cli

echo "[5/8] 📝 Inserting sample movie documents..."
redis-cli <<EOF
HSET movie:11002 title "Star Wars: Episode V - The Empire Strikes Back" plot "..." release_year 1980 genre "Action" rating 8.7 votes 1127635 imdb_id tt0080684
HSET movie:11003 title "The Godfather" plot "..." release_year 1972 genre "Drama" rating 9.2 votes 1563839 imdb_id tt0068646
HSET movie:11004 title "Heat" plot "..." release_year 1995 genre "Thriller" rating 8.2 votes 559490 imdb_id tt0113277
HSET movie:11005 title "Star Wars: Episode VI - Return of the Jedi" plot "..." release_year 1983 genre "Action" rating 8.3 votes 906260 imdb_id tt0086190
EOF

echo "[6/8] 🔍 Creating movie index..."
redis-cli <<EOF
FT.CREATE idx:movie ON hash PREFIX 1 "movie:" SCHEMA title TEXT SORTABLE release_year NUMERIC SORTABLE rating NUMERIC SORTABLE genre TAG SORTABLE
FT.SEARCH idx:movie "war" RETURN 2 title release_year
FT.SEARCH idx:movie "@genre:{Thriller|Action} @title:-jedi" RETURN 2 title release_year
FT.SEARCH idx:movie * FILTER release_year 1970 1980 RETURN 2 title release_year
FT.SEARCH idx:movie "@release_year:[1970 1980]" RETURN 2 title release_year
EOF

echo "[7/8] 🔁 Adding, updating, and expiring a document..."
redis-cli <<EOF
HSET movie:11033 title "Tomorrow Never Dies" plot "..." release_year 1997 genre "Action" rating 6.5 votes 177732 imdb_id tt0120347
FT.SEARCH idx:movie "never" RETURN 2 title release_year
HSET movie:11033 title "Tomorrow Never Dies - 007"
FT.SEARCH idx:movie "007" RETURN 2 title release_year
EXPIRE movie:11033 10
EOF

echo "[⏳] Waiting for document to expire..."
sleep 11
redis-cli FT.SEARCH idx:movie "007"

echo "[8/8] 🎭 Creating filtered Drama index..."
redis-cli <<EOF
FT.CREATE idx:drama ON hash PREFIX 1 "movie:" FILTER "@genre=='Drama' && @release_year>=1990 && @release_year<2000" SCHEMA title TEXT SORTABLE release_year NUMERIC SORTABLE
FT.SEARCH idx:drama "@release_year:[1990 (2000]" LIMIT 0 0
EOF

echo "✅ All steps completed. Now go back to your Qwiklabs window and click 'Check my progress' on each step."
