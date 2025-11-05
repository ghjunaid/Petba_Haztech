<?php

$fromDir = __DIR__ . '/../storage/app/public/adoptionImage';
$toDir = __DIR__ . '/adoptionImage';

// Check if fromDir exists and has files
if (!file_exists($fromDir)) {
    echo "Source directory does not exist: $fromDir\n";
    exit;
}

// Ensure toDir exists
if (!file_exists($toDir)) {
    mkdir($toDir, 0755, true);
    echo "Created target directory: $toDir\n";
}

// Move all files from fromDir to toDir
$files = scandir($fromDir);
foreach ($files as $file) {
    if ($file !== '.' && $file !== '..') {
        $fromFile = $fromDir . '/' . $file;
        $toFile = $toDir . '/' . $file;
        if (rename($fromFile, $toFile)) {
            echo "Moved $file to $toDir\n";
        } else {
            echo "Failed to move $file\n";
        }
    }
}

// Remove the now empty fromDir
if (rmdir($fromDir)) {
    echo "Removed empty source directory: $fromDir\n";
} else {
    echo "Failed to remove source directory\n";
}

echo "Process completed\n";
?>
