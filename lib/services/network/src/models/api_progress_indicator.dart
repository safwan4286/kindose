class ApiProgressIndicator {
  final void Function() showLoader;
  final void Function() hideLoader;

  ApiProgressIndicator({required this.showLoader, required this.hideLoader});
}
