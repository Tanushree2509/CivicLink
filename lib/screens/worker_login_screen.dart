// Add this button to your HomeSelectorScreen after the Admin Login button
SizedBox(
  width: 250,
  child: ElevatedButton(
    onPressed: () {
      // Navigate to worker login screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WorkerLoginScreen()),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green.shade700,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: const BorderSide(color: Colors.white, width: 2),
    ),
    child: const Text(
      'Worker Login',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),