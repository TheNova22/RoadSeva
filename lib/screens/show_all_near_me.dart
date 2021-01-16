import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:road_seva/helpers/location_helper.dart';
import 'package:road_seva/screens/complaint_register.dart';
import 'package:road_seva/widgets/list_pothole.dart';

class PotHolesNearMe extends StatefulWidget {
  const PotHolesNearMe({Key key}) : super(key: key);

  @override
  _PotHolesNearMeState createState() => _PotHolesNearMeState();
}

class _PotHolesNearMeState extends State<PotHolesNearMe> {
  LocationData myLocation;
  void initState() {
    getLoc();
    super.initState();
  }

  Future<void> getLoc() async {
    myLocation = await Location().getLocation();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    LocationHelper lh = new LocationHelper();
    List<DocumentSnapshot> potholes = new List<DocumentSnapshot>();

    if (myLocation == null)
      return Center(
        child: CircularProgressIndicator(),
      );
    @override
    Container potHoleList = Container(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('potholes').snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.connectionState == ConnectionState.none) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          final potholeDoc = snapshot.data.documents;
          return ListView.builder(
              shrinkWrap: true,
              itemCount: potholeDoc.length,
              itemBuilder: (ctx, index) {
                QueryDocumentSnapshot potholeData = potholeDoc[index];
                LatLng p1 =
                    LatLng(potholeData['latitude'], potholeData['longitude']);
                LatLng p2 = LatLng(myLocation.latitude, myLocation.longitude);
                if (lh.getD(p1, p2) > 30)
                  return Container();
                else {
                  print("Added");
                  potholes.add(potholeData);
                }
                return Container(
                  margin: index == potholeDoc.length - 1
                      ? EdgeInsets.only(top: 20)
                      : null,
                  child: ListPotHole(
                    documentSnapshot: potholeData,
                  ),
                );
              });
        },
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Potholes Near Me",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Color(0xfff0f0f0),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20))),
      ),
      body: potHoleList,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.dangerous),
        onPressed: () {
          Navigator.of(context).pushNamed(ComplaintRegisterScreen.routeName,
              arguments: {"location": myLocation, "potholes": potholes});
        },
      ),
    );
  }
}
