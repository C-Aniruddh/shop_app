import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:local_dukaan/utils/constants.dart';
import 'package:local_dukaan/utils/widgets.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:local_dukaan/firebase/auth/phone_auth/get_phone.dart';
import 'package:local_dukaan/firebase/auth/phone_auth/signUpShopkeeper.dart';
import 'package:local_dukaan/firebase/auth/phone_auth/signUpUser.dart';

class LoginPage extends StatefulWidget {
  final Color cardBackgroundColor = Color(0xFF6874C2);
  final String logo = Assets.localdukaan;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  double _height, _width, _fixedPadding;


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    _height = MediaQuery.of(context).size.height;
    _width = MediaQuery.of(context).size.width;
    _fixedPadding = _height * 0.025;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: _getBody(),
          ),
        ),
      ),
    );
  }

  Widget _getBody() => Container(
    child: SizedBox(
      height: _height * 0.8,
      width: _width,
      child: _getColumnBody(),
    ),
  );

  Widget _getColumnBody() => Column(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Padding(
        padding: EdgeInsets.all(_fixedPadding),
        child: PhoneAuthWidgets.getLogo(
            logoPath: widget.logo, height: _height * 0.2),
      ),

      Text("Local Dukaan",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontSize: 24.0,
              fontWeight: FontWeight.w700)),

      Divider(),
      SignInButtonBuilder(
        text: 'Sign in to existing account',
        icon: Icons.account_circle,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PhoneAuthGetPhone()));
        },
        backgroundColor: Theme.of(context).accentColor,
      ),
      SignInButtonBuilder(
        text: 'Sign up as shop owner',
        icon: Icons.shopping_cart,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpShopkeeper()));
        },
        backgroundColor: Theme.of(context).accentColor,
      ),
      SignInButtonBuilder(
        text: 'Sign up as shopper',
        icon: Icons.account_circle,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpUser()));
        },
        backgroundColor: Theme.of(context).accentColor,
      ),
      Divider(),

    ],
  );

}
