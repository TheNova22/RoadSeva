import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:road_seva/helpers/location_helper.dart';

class MapScreen extends StatefulWidget {
  final List<DocumentSnapshot> potholes;

  final double latitude, longitude;
  final bool isSelecting;

  MapScreen({this.isSelecting, this.latitude, this.longitude, this.potholes});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _pickedLocation;
  String address;
  bool _isEnabled = false;
  void _selectLocation(LatLng position) async {
    setState(() {
      _pickedLocation = position;
      _isEnabled = false;
      address = null;
    });
    try {
      address = await LocationHelper.getPlaceAddress(
          position.latitude, position.longitude);
    } finally {
      if (address != null) {
        setState(() {
          _isEnabled = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xfff0f0f0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          "Register a complaint",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
              padding: EdgeInsets.only(right: 10),
              tooltip: "Open Camera",
              alignment: Alignment.center,
              icon: Icon(
                Icons.camera,
                size: 28,
                color: Colors.black,
              ),
              onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            initialCameraPosition: CameraPosition(
                zoom: 18, target: LatLng(widget.latitude, widget.longitude)),
            onTap: widget.isSelecting ? _selectLocation : null,
            markers: (_pickedLocation == null && widget.isSelecting)
                ? {}
                : {
                    Marker(
                      markerId: MarkerId("m1"),
                      position: _pickedLocation ??
                          LatLng(
                            widget.latitude == null ? 0 : widget.latitude,
                            widget.longitude == null ? 0 : widget.longitude,
                          ),
                    ),
                  },
          ),
          Container(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RaisedButton(
                  color: Colors.red[300],
                  onPressed: !_isEnabled
                      ? null
                      : () {
                          var truth = false;
                          String saveid;
                          int upvotes;
                          if (widget.potholes != null)
                            for (DocumentSnapshot element in widget.potholes) {
                              if (element['address'] == address) {
                                truth = true;
                                saveid = element['id'];
                                upvotes = element['upvotes'];
                                break;
                              }
                            }
                          if (truth) {
                            FirebaseFirestore.instance
                                .collection('potholes')
                                .doc(saveid)
                                .update({'upvotes': upvotes + 1});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: Duration(
                                  seconds: 10,
                                ),
                                content: Text(
                                    "We have recieved multiple complaints about this road, and we are working on it!"),
                              ),
                            );
                          } else {
                            var doc = FirebaseFirestore.instance
                                .collection('potholes')
                                .doc();
                            doc.set({
                              'id': doc.id,
                              'isFixed': false,
                              'upvotes': 1,
                              'address': address,
                              'downvotes': 0,
                              'latitude': _pickedLocation.latitude,
                              'longitude': _pickedLocation.longitude
                            });
                          }
                          Navigator.of(context).pop();
                        },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Text(
                    "Report Complaint",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
            ],
          )),
        ],
      ),
    );
  }
}
