// Firebase-specific failure classes
import 'failures.dart';

class FirebaseAuthFailure extends Failure {
  const FirebaseAuthFailure(super.message);
}

class FirebaseFirestoreFailure extends Failure {
  const FirebaseFirestoreFailure(super.message);
}

class FirebaseNetworkFailure extends Failure {
  const FirebaseNetworkFailure(super.message);
}

class FirebaseValidationFailure extends Failure {
  const FirebaseValidationFailure(super.message);
}
