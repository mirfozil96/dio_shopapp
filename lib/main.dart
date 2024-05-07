import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const ProductListScreen(),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  ProductListScreenState createState() => ProductListScreenState();
}

class ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  late TextEditingController textEditingController;
  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
    _fetchProducts();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final products = await _productService.getProducts();
      setState(() {
        _products = products;
        _filteredProducts = products; // Initialize filtered list
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors (e.g., show a snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching products: $e')),
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: TextField(
              onChanged: (text) async {
                await searchProduct(text);
              },
              controller: textEditingController,
              decoration: const InputDecoration(
                labelText: "Search",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(),
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Slidable(
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {},
                              autoClose: false,
                              backgroundColor: const Color(0xFF21B7CA),
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: 'Edit',
                              borderRadius: BorderRadius.circular(20),
                            ),
                            SlidableAction(
                              onPressed: (context) {
                                _deleteProduct(product.id!);
                              },
                              backgroundColor: const Color(0xFFFE4A49),
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              autoClose: false,
                              label: 'Delete',
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ],
                        ),
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: Colors.blueGrey.withOpacity(0.3),
                          elevation: 0,
                          child: ListTile(
                            leading: Image.network(product.images?[0] ??
                                "https://t4.ftcdn.net/jpg/04/73/25/49/360_F_473254957_bxG9yf4ly7OBO5I0O5KABlN930GwaMQz.jpg"),
                            title: Text(product.title ?? "No title"),
                            subtitle: Text("Price: ${product.price}\$"),
                            trailing: Text(product.category ?? ""),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addProduct() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    ).then((newProduct) {
      if (newProduct != null) {
        // Add the new product to the list and update the UI
        setState(() {
          _products.add(newProduct as Product);
          _filteredProducts.add(newProduct);
        });
      }
    });
  }

  void _deleteProduct(int id) async {
    try {
      await _productService.deleteProduct(id);
      setState(() {
        _products.removeWhere((product) => product.id == id);
        _filteredProducts.removeWhere((product) => product.id == id);
      });
    } catch (e) {
      // Handle error (e.g., show a snackbar)
    }
  }

  Future<void> searchProduct(String text) async {
    if (text.isEmpty) {
      setState(() {
        _filteredProducts = _products;
      });
    } else {
      setState(() {
        _filteredProducts = _products
            .where((product) =>
                product.title!.toLowerCase().contains(text.toLowerCase()))
            .toList();
      });
    }
  }
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  AddProductScreenState createState() => AddProductScreenState();
}

class AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  final _productService = ProductService();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addProduct,
                child: const Text('Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addProduct() async {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        title: _nameController.text,
        description: _descriptionController.text,
        price: int.parse(_priceController.text),
      );
      await _productService.addProduct(product);
      Navigator.pop(context, product); // Close the screen after adding
    }
  }
}

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  EditProductScreenState createState() => EditProductScreenState();
}

class EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.title);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProduct,
                child: const Text('Update Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      final updatedProduct = Product(
        id: widget.product.id,
        title: _nameController.text,
        description: _descriptionController.text,
        price: int.parse(_priceController.text),
      );
      await ProductService().updateProduct(updatedProduct);
      Navigator.pop(context, true); // Indicate success
    }
  }
}

class ProductService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://65d3570a522627d50108ac00.mockapi.io/products';

  Future<List<Product>> getProducts() async {
    final response = await _dio.get(baseUrl);
    final List<dynamic> data = response.data;
    return data.map((product) => Product.fromJson(product)).toList();
  }

  Future<Product> addProduct(Product product) async {
    final response = await _dio.post(baseUrl, data: product.toJson());
    return Product.fromJson(response.data);
  }

  Future<void> deleteProduct(int id) async {
    await _dio.delete('$baseUrl/$id');
  }

  Future<Product> updateProduct(Product product) async {
    final response =
        await _dio.put('$baseUrl/${product.id}', data: product.toJson());
    return Product.fromJson(response.data);
  }
}

AllProductModel allProductModelFromJson(String str) =>
    AllProductModel.fromJson(json.decode(str));
String allProductModelToJson(AllProductModel data) =>
    json.encode(data.toJson());

class AllProductModel {
  AllProductModel({
    this.products,
    this.total,
    this.skip,
    this.limit,
  });

  AllProductModel.fromJson(dynamic json) {
    if (json['products'] != null) {
      products = [];
      json['products'].forEach((v) {
        products?.add(Product.fromJson(v));
      });
    }
    total = json['total'];
    skip = json['skip'];
    limit = json['limit'];
  }
  List<Product>? products;
  int? total;
  int? skip;
  int? limit;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (products != null) {
      map['products'] = products?.map((v) => v.toJson()).toList();
    }
    map['total'] = total;
    map['skip'] = skip;
    map['limit'] = limit;
    return map;
  }
}

Product productsFromJson(String str) => Product.fromJson(json.decode(str));
String productsToJson(Product data) => json.encode(data.toJson());

class Product {
  Product({
    this.id,
    this.title,
    this.description,
    this.price,
    this.discountPercentage,
    this.rating,
    this.stock,
    this.brand,
    this.category,
    this.thumbnail,
    this.images,
  });

  int? id;
  String? title;
  String? description;
  int? price;
  num? discountPercentage;
  num? rating;
  int? stock;
  String? brand;
  String? category;
  String? thumbnail;
  List<String>? images;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        price: json['price'],
        discountPercentage: json['discountPercentage'],
        rating: json['rating'],
        stock: json['stock'],
        brand: json['brand'],
        category: json['category'],
        thumbnail: json['thumbnail'],
        images:
            json['images'] != null ? List<String>.from(json['images']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'price': price,
        'discountPercentage': discountPercentage,
        'rating': rating,
        'stock': stock,
        'brand': brand,
        'category': category,
        'thumbnail': thumbnail,
        'images': images,
      };
}
