import 'package:client/src/widget/circle_border_button.dart';
import 'package:client/src/widget/white_border_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:client/src/auxiliary/asset_path.dart';
import 'package:client/src/icon/korea_monkey_icons.dart';

import 'package:client/src/model/thumbnail_editor.dart';

import 'dart:io';

class ThumbnailResizeView extends StatefulWidget {
  @override
  _ThumbnailResizeViewState createState() => _ThumbnailResizeViewState();

  static final double thumbnail_size = 220.0;
  ThumbnailEditor editor = ThumbnailEditor(size: thumbnail_size);
}

class ThumbNailMask extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = Colors.black.withOpacity(0.5);

    final Path path = Path();
    path.fillType = PathFillType.evenOdd;
    path.addRRect(RRect.fromRectAndCorners(
      Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width,
          height: size.height),
    ));
    path.addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2 - 2));

    canvas.drawPath(path, paint);

    {
      final paint = Paint();
      paint.color = Colors.green;

      final Path path = Path();
      path.fillType = PathFillType.evenOdd;
      path.addOval(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2));
      path.addOval(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2 - 2));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class _ThumbnailResizeViewState extends State<ThumbnailResizeView> {
  @override
  initState() {
    widget.editor.initialize(() {
      setState(() {});
    });
  }

  Widget getTitleView(BuildContext context) {
    var text = Row(children: <Widget>[
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '얼굴사진 조절',
          style: TextStyle(
              fontSize: 30, fontFamily: 'Shinb7', color: Colors.white),
        ),
      ),
      Icon(KoreaMonkey.title_icon, color: Colors.white, size: 28)
    ]);
    return Row(children: [
      Container(
          alignment: Alignment.topLeft,
          child: TextButton(onPressed: () {}, child: text)),
      Expanded(child: Container())
    ]);
  }

  Widget getThumbnailMaskView(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(painter: ThumbNailMask()),
    );
  }

  double start_x = 0.0;
  double start_y = 0.0;
  double end_x = 0.0;
  double end_y = 0.0;

  Widget getThumbnailGestureDetector(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        end_x = start_x = details.localPosition.dx;
        print("Start X : $start_x");
        end_y = start_y = details.localPosition.dy;
        print("Start Y : $start_y");
      },
      onPanUpdate: (details) {
        start_x = end_x;
        end_x = details.localPosition.dx;
        print("End X : $end_x");
        start_y = end_y;
        end_y = details.localPosition.dy;
        print("End Y : $end_y");

        widget.editor.setPosition(end_x - start_x, end_y - start_y);
      },
    );
  }

  Widget getThumbnailMouseWheelDetector(BuildContext context, Widget child) {
    return Listener(
        onPointerSignal: (pointerSignal) {
          print("Event OK?");
          if (pointerSignal is PointerScrollEvent) {
            var event = pointerSignal as PointerScrollEvent;
            if (event.scrollDelta.dy > 0.0)
              widget.editor.downMagnification();
            else if (event.scrollDelta.dy < 0.0)
              widget.editor.upMagnification();
          }
        },
        child: child);
  }

  Future<Image> _getImage() async {
    print("Get Image");
    //print(widget.editor.data);

    return Image.memory(
      widget.editor.data,
      width: widget.editor.width,
      height: widget.editor.height,
      fit: BoxFit.fill,
    );
  }

  Widget getThumbnailView(BuildContext context) {
    var futureImage = FutureBuilder<Image>(
      future: _getImage(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!;
        }

        print("Image Waiting...");
        return Image.asset(
          "image/test/thumbnail1.png",
          width: ThumbnailResizeView.thumbnail_size,
          height: ThumbnailResizeView.thumbnail_size,
          fit: BoxFit.fill,
        );
      },
    );

    return Container(
        width: ThumbnailResizeView.thumbnail_size,
        height: ThumbnailResizeView.thumbnail_size,
        child: getThumbnailMouseWheelDetector(
            context,
            Stack(children: [
              Positioned(
                left: widget.editor.x,
                top: widget.editor.y,
                child: futureImage,
              ),
              getThumbnailMaskView(context, ThumbnailResizeView.thumbnail_size),
              getThumbnailGestureDetector(context),
            ])));
  }

  Widget getSliderView(BuildContext context) {
    return Container(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleBorderButton(
            size: 25,
            child: Icon(KoreaMonkey.minus, color: Colors.white, size: 22),
            onPressed: widget.editor.downMagnification),
        Slider(
          inactiveColor: Colors.white.withOpacity(0.5),
          activeColor: Colors.white70,
          //thumbColor: Colors.white,
          value: widget.editor.magnification,
          min: widget.editor.magnification_min,
          max: widget.editor.magnification_max,
          divisions: widget.editor.magnification_division,
          label: widget.editor.magnification.toString(),
          onChanged: widget.editor.changeMagnification,
        ),
        CircleBorderButton(
          size: 25,
          child: Icon(KoreaMonkey.plus, color: Colors.white, size: 22),
          onPressed: widget.editor.upMagnification,
        ),
      ],
    ));
  }

  Widget getFindButtonView(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
      child: WhiteBorderButton(
        data: "찾기",
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        fontSize: 20.0,
        onPressed: widget.editor.find,
      ),
    );
  }

  Widget getConfirmButtonView(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
      child: WhiteBorderButton(
        data: "확인",
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        fontSize: 20.0,
        onPressed: () {},
      ),
    );
  }

  Widget getCancelButtonView(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
      child: WhiteBorderButton(
        data: "취소",
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        fontSize: 20.0,
        onPressed: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            getTitleView(context),
            Expanded(child: Container()),
            getThumbnailView(context),
            getSliderView(context),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  getFindButtonView(context),
                  getConfirmButtonView(context),
                  getCancelButtonView(context),
                ],
              ),
            )
          ],
        ));
  }
}
