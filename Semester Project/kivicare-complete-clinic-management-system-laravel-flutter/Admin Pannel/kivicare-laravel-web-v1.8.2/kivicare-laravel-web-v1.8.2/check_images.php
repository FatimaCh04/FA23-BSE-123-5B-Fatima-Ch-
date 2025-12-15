<?php
$db = new PDO('sqlite:database/database.sqlite');

// List all tables
echo "=== ALL TABLES ===" . PHP_EOL;
$stmt = $db->query("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    echo $row['name'] . PHP_EOL;
}

// Check media table model types
echo PHP_EOL . "=== MEDIA MODEL TYPES ===" . PHP_EOL;
$stmt = $db->query("SELECT DISTINCT model_type FROM media");
while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    echo $row['model_type'] . PHP_EOL;
}

