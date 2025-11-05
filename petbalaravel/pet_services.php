<?php
// Start session and DB connection
session_start();
$conn = new mysqli("localhost", "root", "", "petba");

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Handle form submission
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $formType = $_POST['form_type'];

    if ($formType == "shelter") {
        $name = $_POST['name'];
        $owner = $_POST['owner'];
        $address = $_POST['address'];
        $phone = $_POST['phone'];
        $description = $_POST['description'];

        $sql = "INSERT INTO shelter (name, owner, address, phoneNumber, description)
                VALUES ('$name', '$owner', '$address', '$phone', '$description')";
    }

    elseif ($formType == "foster") {
        $name = $_POST['name'];
        $owner = $_POST['owner'];
        $address = $_POST['address'];
        $phone = $_POST['phone'];
        $description = $_POST['description'];

        $sql = "INSERT INTO foster (name, owner, address, phoneNumber, description)
                VALUES ('$name', '$owner', '$address', '$phone', '$description')";
    }

    elseif ($formType == "groomer") {
        $name = $_POST['name'];
        $service = $_POST['service'];
        $experience = $_POST['experience'];
        $contact = $_POST['contact'];

        $sql = "INSERT INTO groomers (name, service_type, experience, contact)
                VALUES ('$name', '$service', '$experience', '$contact')";
    }

    elseif ($formType == "trainer") {
        $name = $_POST['name'];
        $specialty = $_POST['specialty'];
        $experience = $_POST['experience'];
        $contact = $_POST['contact'];

        $sql = "INSERT INTO trainers (name, specialty, experience, contact)
                VALUES ('$name', '$specialty', '$experience', '$contact')";
    }

    if ($conn->query($sql) === TRUE) {
        echo "<p style='color:green;'>Record added successfully to <b>$formType</b> table!</p>";
    } else {
        echo "<p style='color:red;'>Error: " . $conn->error . "</p>";
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Pet Services</title>
    <style>
        body { font-family: Arial, sans-serif; background:#111; color:white; }
        .tabs { display: flex; gap: 20px; margin-bottom: 20px; }
        .tab { padding:10px 20px; background:#333; cursor:pointer; border-radius:8px; }
        .tab:hover { background:#444; }
        .form-container { display: none; background:#222; padding:20px; border-radius:10px; width:400px; }
        input, textarea { width:100%; padding:8px; margin:5px 0; border:none; border-radius:5px; }
        button { background:#007BFF; color:white; padding:10px; width:100%; border:none; border-radius:5px; cursor:pointer; }
        button:hover { background:#0056b3; }
    </style>
    <script>
        function showForm(id) {
            document.querySelectorAll('.form-container').forEach(f => f.style.display = "none");
            document.getElementById(id).style.display = "block";
        }
    </script>
</head>
<body>
    <h1>Pet Services Management</h1>

    <div class="tabs">
        <div class="tab" onclick="showForm('shelterForm')">Shelters</div>
        <div class="tab" onclick="showForm('fosterForm')">Fosters</div>
        <div class="tab" onclick="showForm('groomerForm')">Groomers</div>
        <div class="tab" onclick="showForm('trainerForm')">Trainers</div>
    </div>

    <!-- Shelter Form -->
    <div class="form-container" id="shelterForm">
        <h2>Add Shelter</h2>
        <form method="POST">
            <input type="hidden" name="form_type" value="shelter">
            <input type="text" name="name" placeholder="Shelter Name" required>
            <input type="text" name="owner" placeholder="Owner Name" required>
            <input type="text" name="address" placeholder="Address" required>
            <input type="text" name="phone" placeholder="Phone Number" required>
            <textarea name="description" placeholder="Description"></textarea>
            <button type="submit">Save Shelter</button>
        </form>
    </div>

    <!-- Foster Form -->
    <div class="form-container" id="fosterForm">
        <h2>Add Foster</h2>
        <form method="POST">
            <input type="hidden" name="form_type" value="foster">
            <input type="text" name="name" placeholder="Foster Name" required>
            <input type="text" name="owner" placeholder="Owner Name" required>
            <input type="text" name="address" placeholder="Address" required>
            <input type="text" name="phone" placeholder="Phone Number" required>
            <textarea name="description" placeholder="Description"></textarea>
            <button type="submit">Save Foster</button>
        </form>
    </div>

    <!-- Groomer Form -->
    <div class="form-container" id="groomerForm">
        <h2>Add Groomer</h2>
        <form method="POST">
            <input type="hidden" name="form_type" value="groomer">
            <input type="text" name="name" placeholder="Groomer Name" required>
            <input type="text" name="service" placeholder="Service Type" required>
            <input type="number" name="experience" placeholder="Experience (years)" required>
            <input type="text" name="contact" placeholder="Contact" required>
            <button type="submit">Save Groomer</button>
        </form>
    </div>

    <!-- Trainer Form -->
    <div class="form-container" id="trainerForm">
        <h2>Add Trainer</h2>
        <form method="POST">
            <input type="hidden" name="form_type" value="trainer">
            <input type="text" name="name" placeholder="Trainer Name" required>
            <input type="text" name="specialty" placeholder="Specialty" required>
            <input type="number" name="experience" placeholder="Experience (years)" required>
            <input type="text" name="contact" placeholder="Contact" required>
            <button type="submit">Save Trainer</button>
        </form>
    </div>
</body>
</html>
