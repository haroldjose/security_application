# Sistema Medicamentos

#### maestrante: Harold Joseph Sanchez Nogales
#### Descargar apk aplicación:   [app-release.apk](https://drive.google.com/drive/folders/1YqFIpQI1UxAjoRcH-TMIX0nNG1e8TFjJ?usp=sharing)

En la aplicación se puede registrar dos usuarios **Administrador** y **Doctor**.

El usuario **Administrador** solo nesecita nombre y contraseña para registrarse y puede:
* Registrar medicamentos mediante formulario y QR.
* Ver los medicamentos registrados.
* Eliminar los medicamentos.
* Editar el registro del medicamento.
* Ver los retiros de medicamentos que realiza el usuario doctor.
* Colocar una iamgen de perfil, ya sea tomando una foto o cargando desde galeria.

El usuario **Doctor** solo nesecita nombre,especialidad y contraseña para registrarse y puede:
* Ver medicamentos registrados.
* no puede eliminar, ni registrar medicamentos.
* Retirar medicamentos, seleccionando el medicamento y colocando la cantidad a retirar.
* Colocar una iamgen de perfil, ya sea tomando una foto o cargando desde galeria.

#### Formato imgen qr
Paracetamol,Quimfa,Chile,Analgésico,1.5,50
![dexa](img/para.png)



dexametasona,Pfizer,Alemania,cápsula,10.5,100
![dexa](img/dexa.png)

#### El presente proyecto esta realizado con **Riverpod** que proporciona una forma moderna y eficiente de gestionar el estado de las aplicaciones Flutter.


```
lib/
├── main.dart
├── core/
│   └── providers.dart
├── data/
│   ├── datasources/
│   │   └── db_helper.dart
│   └── models/
│   |    ├── medicamento_model.dart
│   |    └── user_model.dart
│   ├── repositories/
│   │    └── app_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── medicamento.dart
│   │   └── user.dart
│   │   └── retiro.dart
│   ├── repositories/
│   │   └── app_repository_impl.dart
├── application/
│   ├── providers/
│   │   ├── medicamento_provider.dart
│   │   └── user_provider.dart
├── presentation/
│   ├── pages/
│   │   ├── login_page.dart
│   │   ├── register_page.dart
│   │   ├── admin_dashboard.dart
│   │   ├── qr_scan_page.dart
│   │   ├── doctor_dashboard.dart
│   │   └── retiro_medicamentos_page.dart
│   └── widgets/
│       └── common_widgets.dart
```




