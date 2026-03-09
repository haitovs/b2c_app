/// Maps a country display name to its flag emoji.
/// Returns empty string if country is not recognized.
String countryNameToFlag(String? countryName) {
  if (countryName == null || countryName.isEmpty) return '';
  final code = _countryNameToCode[countryName.toLowerCase()];
  if (code == null) return '';
  // Convert 2-letter ISO code to flag emoji using regional indicator symbols
  const flagOffset = 0x1F1E6;
  const asciiOffset = 0x41;
  final first = code.codeUnitAt(0) - asciiOffset + flagOffset;
  final second = code.codeUnitAt(1) - asciiOffset + flagOffset;
  return String.fromCharCodes([first, second]);
}

const _countryNameToCode = <String, String>{
  // A
  'afghanistan': 'AF',
  'albania': 'AL',
  'algeria': 'DZ',
  'andorra': 'AD',
  'angola': 'AO',
  'antigua and barbuda': 'AG',
  'argentina': 'AR',
  'armenia': 'AM',
  'australia': 'AU',
  'austria': 'AT',
  'azerbaijan': 'AZ',

  // B
  'bahamas': 'BS',
  'the bahamas': 'BS',
  'bahrain': 'BH',
  'bangladesh': 'BD',
  'barbados': 'BB',
  'belarus': 'BY',
  'belgium': 'BE',
  'belize': 'BZ',
  'benin': 'BJ',
  'bhutan': 'BT',
  'bolivia': 'BO',
  'bosnia and herzegovina': 'BA',
  'botswana': 'BW',
  'brazil': 'BR',
  'brunei': 'BN',
  'bulgaria': 'BG',
  'burkina faso': 'BF',
  'burundi': 'BI',

  // C
  'cabo verde': 'CV',
  'cape verde': 'CV',
  'cambodia': 'KH',
  'cameroon': 'CM',
  'canada': 'CA',
  'central african republic': 'CF',
  'chad': 'TD',
  'chile': 'CL',
  'china': 'CN',
  'colombia': 'CO',
  'comoros': 'KM',
  'congo': 'CG',
  'republic of the congo': 'CG',
  'democratic republic of the congo': 'CD',
  'dr congo': 'CD',
  'costa rica': 'CR',
  'croatia': 'HR',
  'cuba': 'CU',
  'cyprus': 'CY',
  'czech republic': 'CZ',
  'czechia': 'CZ',

  // D
  'denmark': 'DK',
  'djibouti': 'DJ',
  'dominica': 'DM',
  'dominican republic': 'DO',

  // E
  'east timor': 'TL',
  'timor-leste': 'TL',
  'ecuador': 'EC',
  'egypt': 'EG',
  'el salvador': 'SV',
  'equatorial guinea': 'GQ',
  'eritrea': 'ER',
  'estonia': 'EE',
  'eswatini': 'SZ',
  'swaziland': 'SZ',
  'ethiopia': 'ET',

  // F
  'fiji': 'FJ',
  'finland': 'FI',
  'france': 'FR',

  // G
  'gabon': 'GA',
  'gambia': 'GM',
  'the gambia': 'GM',
  'georgia': 'GE',
  'germany': 'DE',
  'ghana': 'GH',
  'greece': 'GR',
  'grenada': 'GD',
  'guatemala': 'GT',
  'guinea': 'GN',
  'guinea-bissau': 'GW',
  'guyana': 'GY',

  // H
  'haiti': 'HT',
  'honduras': 'HN',
  'hungary': 'HU',

  // I
  'iceland': 'IS',
  'india': 'IN',
  'indonesia': 'ID',
  'iran': 'IR',
  'iraq': 'IQ',
  'ireland': 'IE',
  'israel': 'IL',
  'italy': 'IT',
  'ivory coast': 'CI',
  "cote d'ivoire": 'CI',

  // J
  'jamaica': 'JM',
  'japan': 'JP',
  'jordan': 'JO',

  // K
  'kazakhstan': 'KZ',
  'kenya': 'KE',
  'kiribati': 'KI',
  'north korea': 'KP',
  'south korea': 'KR',
  'korea': 'KR',
  'kosovo': 'XK',
  'kuwait': 'KW',
  'kyrgyzstan': 'KG',

  // L
  'laos': 'LA',
  'latvia': 'LV',
  'lebanon': 'LB',
  'lesotho': 'LS',
  'liberia': 'LR',
  'libya': 'LY',
  'liechtenstein': 'LI',
  'lithuania': 'LT',
  'luxembourg': 'LU',

  // M
  'madagascar': 'MG',
  'malawi': 'MW',
  'malaysia': 'MY',
  'maldives': 'MV',
  'mali': 'ML',
  'malta': 'MT',
  'marshall islands': 'MH',
  'mauritania': 'MR',
  'mauritius': 'MU',
  'mexico': 'MX',
  'micronesia': 'FM',
  'federated states of micronesia': 'FM',
  'moldova': 'MD',
  'monaco': 'MC',
  'mongolia': 'MN',
  'montenegro': 'ME',
  'morocco': 'MA',
  'mozambique': 'MZ',
  'myanmar': 'MM',
  'burma': 'MM',

  // N
  'namibia': 'NA',
  'nauru': 'NR',
  'nepal': 'NP',
  'netherlands': 'NL',
  'the netherlands': 'NL',
  'new zealand': 'NZ',
  'nicaragua': 'NI',
  'niger': 'NE',
  'nigeria': 'NG',
  'north macedonia': 'MK',
  'macedonia': 'MK',
  'norway': 'NO',

  // O
  'oman': 'OM',

  // P
  'pakistan': 'PK',
  'palau': 'PW',
  'palestine': 'PS',
  'panama': 'PA',
  'papua new guinea': 'PG',
  'paraguay': 'PY',
  'peru': 'PE',
  'philippines': 'PH',
  'poland': 'PL',
  'portugal': 'PT',

  // Q
  'qatar': 'QA',

  // R
  'romania': 'RO',
  'russia': 'RU',
  'russian federation': 'RU',
  'rwanda': 'RW',

  // S
  'saint kitts and nevis': 'KN',
  'st. kitts and nevis': 'KN',
  'saint lucia': 'LC',
  'st. lucia': 'LC',
  'saint vincent and the grenadines': 'VC',
  'st. vincent and the grenadines': 'VC',
  'samoa': 'WS',
  'san marino': 'SM',
  'sao tome and principe': 'ST',
  'saudi arabia': 'SA',
  'senegal': 'SN',
  'serbia': 'RS',
  'seychelles': 'SC',
  'sierra leone': 'SL',
  'singapore': 'SG',
  'slovakia': 'SK',
  'slovenia': 'SI',
  'solomon islands': 'SB',
  'somalia': 'SO',
  'south africa': 'ZA',
  'south sudan': 'SS',
  'spain': 'ES',
  'sri lanka': 'LK',
  'sudan': 'SD',
  'suriname': 'SR',
  'sweden': 'SE',
  'switzerland': 'CH',
  'syria': 'SY',
  'syrian arab republic': 'SY',

  // T
  'taiwan': 'TW',
  'tajikistan': 'TJ',
  'tanzania': 'TZ',
  'thailand': 'TH',
  'togo': 'TG',
  'tonga': 'TO',
  'trinidad and tobago': 'TT',
  'tunisia': 'TN',
  'turkey': 'TR',
  'turkmenistan': 'TM',
  'tuvalu': 'TV',

  // U
  'uganda': 'UG',
  'ukraine': 'UA',
  'united arab emirates': 'AE',
  'uae': 'AE',
  'united kingdom': 'GB',
  'uk': 'GB',
  'united states': 'US',
  'united states of america': 'US',
  'usa': 'US',
  'uruguay': 'UY',
  'uzbekistan': 'UZ',

  // V
  'vanuatu': 'VU',
  'vatican city': 'VA',
  'holy see': 'VA',
  'venezuela': 'VE',
  'vietnam': 'VN',
  'viet nam': 'VN',

  // Y
  'yemen': 'YE',

  // Z
  'zambia': 'ZM',
  'zimbabwe': 'ZW',
};
