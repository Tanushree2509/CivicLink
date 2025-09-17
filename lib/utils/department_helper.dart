class DepartmentHelper {
  // Get department based on category
  static String getDepartmentForCategory(String category) {
    final lowerCategory = category.toLowerCase();
    
    if (lowerCategory.contains('pothole') || 
        lowerCategory.contains('road') || 
        lowerCategory.contains('bridge') ||
        lowerCategory.contains('infrastructure')) {
      return 'Roads & Infrastructure';
    } else if (lowerCategory.contains('garbage') || 
               lowerCategory.contains('trash') || 
               lowerCategory.contains('sanitation') ||
               lowerCategory.contains('waste') ||
               lowerCategory.contains('clean')) {
      return 'Sanitation';
    } else if (lowerCategory.contains('streetlight') || 
               lowerCategory.contains('light') || 
               lowerCategory.contains('electric') ||
               lowerCategory.contains('power')) {
      return 'Electricity';
    } else if (lowerCategory.contains('water') || 
               lowerCategory.contains('sewage') ||
               lowerCategory.contains('drain')) {
      return 'Water & Sewage';
    } else {
      return 'Other Issues';
    }
  }
}