String currencySymbol(String currency) {
  switch (currency) {
    case 'usd':
      return '\$';
    case 'eur':
      return '€';
    case 'gbp':
      return '£';
    case 'ngn':
      return '₦';
    default:
      return '\$';
  }
}