
class CustomerModel {
  String? customerUUID;
  String? firstName;
  String? surName;
  String? phoneNumber;
  String? phoneNumber2;
  String? email;
  List<String>? searchTerms;

  CustomerModel({required this.customerUUID, required this.firstName, required this.surName,
    required this.phoneNumber, this.phoneNumber2, this.email,required this.searchTerms});

}
