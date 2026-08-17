/// Cavite & Bulihan Location Specification
/// Derived directly from Saddle Ranch System Spec (Section 1)
library;

// 1. Bulihan Core Barangays (11 Barangays)
const List<String> bulihanBarangays = [
  'Anahaw II',
  'Anahaw I',
  'Acacia',
  'Banaba',
  'Ipil I',
  'Ipil II',
  'Narra I',
  'Narra II',
  'Narra III',
  'Yakal',
  'Bulihan Proper',
];

// 2. Cavite Cities & Barangays Mapping
const Map<String, List<String>> caviteLocations = {
  'Silang': [
    ...bulihanBarangays,
    'Biga I',
    'Biga II',
    'Carmen',
    'Lucsuhin',
    'Poblacion I',
    'Poblacion II',
    'Sabutan',
    'San Vicente',
    'Tubuan',
    'Other Silang Barangay',
  ],
  'Dasmariñas City': [
    'Sampaloc 1',
    'Sampaloc 2',
    'Salawag',
    'Paliparan 1',
    'Paliparan 2',
    'Paliparan 3',
    'Langgaan',
    'San Agustin 1',
    'San Agustin 2',
    'Other Dasmariñas Barangay',
  ],
  'General Trias': [
    'Manggahan',
    'San Francisco',
    'Navarro',
    'Tejero',
    'Other Gen. Trias Barangay',
  ],
  'Imus City': [
    'Anabu I-A',
    'Bucandala',
    'Malagasang I-A',
    'Poblacion',
    'Other Imus Barangay',
  ],
  'Bacoor City': [
    'Molino 1',
    'Molino 2',
    'Molino 3',
    'Queens Row',
    'Other Bacoor Barangay',
  ],
  'Tagaytay City': [
    'Maharlika',
    'Mendez Crossing',
    'Sungay',
    'Other Tagaytay Barangay',
  ],
  'Other Cavite Municipality': [
    'Poblacion / Local Barangay',
  ],
};

const String defaultRegion = 'Region IV-A (CALABARZON)';
const String defaultProvince = 'Cavite';
const String defaultCity = 'Silang';
const String defaultBarangay = 'Anahaw II';

/// Checks if an address is located in the Bulihan Free Delivery area
bool isBulihanArea({String? city, String? barangay, String? fullAddress}) {
  if (barangay != null && bulihanBarangays.any((b) => b.toLowerCase() == barangay.trim().toLowerCase())) {
    return true;
  }
  if (fullAddress != null && fullAddress.toLowerCase().contains('bulihan')) {
    return true;
  }
  if (city != null && city.toLowerCase().contains('bulihan')) {
    return true;
  }
  return false;
}

/// Constructs formatted delivery address string:
/// "${streetAddress.trim()}, Brgy. ${barangay}, ${city}, ${province}, ${region}"
String buildDeliveryAddressString({
  required String streetAddress,
  required String barangay,
  required String city,
  String province = defaultProvince,
  String region = defaultRegion,
}) {
  return '${streetAddress.trim()}, Brgy. ${barangay.trim()}, ${city.trim()}, $province, $region';
}
