const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

// In-memory database
let products = [
    { id: 1, name: 'Laptop', price: 999, stock: 10 },
    { id: 2, name: 'Mouse', price: 25, stock: 50 },
    { id: 3, name: 'Keyboard', price: 75, stock: 30 }
];

// Get all products
app.get('/products', (req, res) => {
    res.json(products);
});

// Get product by ID
app.get('/products/:id', (req, res) => {
    const product = products.find(p => p.id === parseInt(req.params.id));
    if (!product) {
        return res.status(404).json({ error: 'Product not found' });
    }
    res.json(product);
});

// Create new product
app.post('/products', (req, res) => {
    const { name, price, stock } = req.body;
    const newProduct = {
        id: products.length + 1,
        name,
        price: parseFloat(price),
        stock: parseInt(stock)
    };
    products.push(newProduct);
    res.status(201).json(newProduct);
});

// Update product stock
app.patch('/products/:id/stock', (req, res) => {
    const productId = parseInt(req.params.id);
    const { quantity } = req.body;
    const product = products.find(p => p.id === productId);

    if (!product) {
        return res.status(404).json({ error: 'Product not found' });
    }

    if (product.stock < quantity) {
        return res.status(400).json({ error: 'Insufficient stock' });
    }

    product.stock -= quantity;
    res.json(product);
});

// Health check
app.get('/health', (req, res) => {
    res.json({
        service: 'product-service',
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        service: 'Product Service',
        version: '1.0.0',
        endpoints: [
            'GET /products - Get all products',
            'GET /products/:id - Get product by ID',
            'POST /products - Create product',
            'PATCH /products/:id/stock - Update stock',
            'GET /health - Health check'
        ]
    });
});

const PORT = process.env.PORT || 3002;
app.listen(PORT, () => {
    console.log(`Product Service running on port ${PORT}`);
});
