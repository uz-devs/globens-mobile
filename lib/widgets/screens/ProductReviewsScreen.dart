import 'package:globens_flutter_client/entities/AppUser.dart';
import 'package:globens_flutter_client/entities/Product.dart';
import 'package:globens_flutter_client/entities/Review.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:globens_flutter_client/utils/Locale.dart';
import 'package:globens_flutter_client/utils/Utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProductReviewsScreen extends StatefulWidget {
  static const String route_name = '/product_reviews_screen';

  @override
  State<StatefulWidget> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  var _reviews = <Review>[];

  Product _product;
  var _newReviewStars = 0;
  final _newReviewTitleController = TextEditingController();
  final _newReviewController = TextEditingController();
  RefreshController _refreshController;

  @override
  void initState() {
    super.initState();

    _refreshController = RefreshController(initialRefresh: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _product = ModalRoute.of(context).settings.arguments as Product;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(240, 242, 245, 1),
      appBar: AppBar(leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.of(context).pop()), backgroundColor: Colors.blue, title: Text(Locale.get("Ratings and Reviews"), overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white))),
      body: SmartRefresher(
        enablePullDown: true,
        enablePullUp: true,
        header: MaterialClassicHeader(color: Colors.blue,),
        footer: CustomFooter(
          builder: (BuildContext context, LoadStatus mode) {
            Widget body;
            if (mode == LoadStatus.idle)
              body = Text("Pull up to load more");
            else if (mode == LoadStatus.loading)
              body = Text("Loading");
            else if (mode == LoadStatus.failed)
              body = Text("Load Failed! Click retry!");
            else if (mode == LoadStatus.canLoading)
              body = Text("release to load more");
            else
              body = Text("No more Data");
            return Container(
              height: 55.0,
              child: Center(child: body),
            );
          },
        ),
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: ListView.builder(
          padding: EdgeInsets.all(10.0),
          itemCount: _reviews.length + 1,
          itemBuilder: (context, index) => _buildRow(index),
        ),
      ),
    );
  }

  void _onRefresh() async {
    var res = await grpcFetchProductReviews(AppUser.sessionKey, _product.id);
    if (res.item1 && mounted)
      setState(() {
        _reviews = res.item2;
      });
    _refreshController.refreshCompleted();
  }

  Widget _buildRow(int index) {
    if (index == _reviews.length)
      return Wrap(
        children: [
          getSectionSplitter(Locale.get("Write a review")),
          TextFormField(
            controller: _newReviewTitleController,
            keyboardType: TextInputType.text,
            maxLength: 120,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
            decoration: InputDecoration(border: OutlineInputBorder(), hintText: Locale.get("Review title")),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 20.0),
            child: Center(
              child: RatingBar.builder(
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) => _newReviewStars = rating.toInt(),
              ),
            ),
          ),
          TextFormField(
            controller: _newReviewController,
            keyboardType: TextInputType.multiline,
            maxLines: 5,
            maxLength: 500,
            style: TextStyle(fontSize: 16.0),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: Locale.get("Review message (optional)"),
            ),
          ),
          Center(
            child: RaisedButton.icon(
              onPressed: _postNewReview,
              color: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
              icon: Icon(Icons.send, color: Colors.white),
              label: Text(Locale.get("Submit"), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    else
      return Container(
        padding: EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(Locale.get("Anonymous user"), style: TextStyle(fontSize: 16.0, color: Colors.blue)),
            SizedBox(height: 4.0),
            RatingBarIndicator(
              rating: _reviews[index].stars.toDouble(),
              direction: Axis.horizontal,
              itemCount: 5,
              itemSize: 15.0,
              itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
            ),
            if (_reviews[index].review.isNotEmpty) SizedBox(height: 4.0),
            if (_reviews[index].review.isNotEmpty) Text("${_reviews[index].review}", style: TextStyle(fontSize: 16.0)),
          ],
        ),
      );
  }

  void _postNewReview() async {
    final newReviewTitle = _newReviewTitleController.text.toString();
    final newReviewMessage = _newReviewController.text.toString();
    bool isSuccess = await grpcSubmitProductReview(AppUser.sessionKey, _product, _newReviewStars, newReviewMessage);
    if (isSuccess) {
      await toast(Locale.get("Submitted"));
      Navigator.of(context).pop();
    } else {
      await toast(Locale.get("Try again later"));
    }
  }
}
