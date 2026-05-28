DROP DATABASE IF EXISTS store_db;
CREATE DATABASE store_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE store_db;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(150),
    email VARCHAR(150),
    role VARCHAR(50) DEFAULT 'admin',
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE suppliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150),
    phone VARCHAR(30),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    supplier VARCHAR(150),
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    quantity INT NOT NULL DEFAULT 0,
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    buyer_type VARCHAR(50),
    customer_name VARCHAR(150),
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2),
    total_amount DECIMAL(10,2) NOT NULL,
    sale_date DATE,
    remarks TEXT,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
);

CREATE TABLE requirements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(150),
    requested_by VARCHAR(150),
    item_name VARCHAR(150),
    quantity INT,
    purpose TEXT,
    request_date DATE,
    status VARCHAR(50) DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE approvals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    requirement_id INT,
    approved_by VARCHAR(150),
    approval_status VARCHAR(50),
    remarks TEXT,
    approval_date DATE,
    FOREIGN KEY(requirement_id) REFERENCES requirements(id) ON DELETE CASCADE
);

CREATE TABLE purchase_orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    po_number VARCHAR(100) UNIQUE,
    requirement_id INT,
    supplier_id INT,
    supplier_name VARCHAR(150),
    po_date DATE,
    total_amount DECIMAL(10,2),
    po_status VARCHAR(50) DEFAULT 'Generated',
    FOREIGN KEY(requirement_id) REFERENCES requirements(id) ON DELETE SET NULL,
    FOREIGN KEY(supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
);

CREATE TABLE received_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    po_id INT,
    product_id INT,
    received_quantity INT,
    received_by VARCHAR(150),
    receive_date DATE,
    remarks TEXT,
    FOREIGN KEY(po_id) REFERENCES purchase_orders(id) ON DELETE SET NULL,
    FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE SET NULL
);

CREATE TABLE departments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(150) NOT NULL UNIQUE,
    contact_person VARCHAR(150),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE item_transfers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    department_id INT,
    requirement_id INT NULL,
    transfer_quantity INT NOT NULL,
    transfer_type VARCHAR(50) DEFAULT 'Issue',
    issued_to VARCHAR(150),
    issued_by VARCHAR(150),
    transfer_date DATE,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE SET NULL,
    FOREIGN KEY(department_id) REFERENCES departments(id) ON DELETE SET NULL,
    FOREIGN KEY(requirement_id) REFERENCES requirements(id) ON DELETE SET NULL
);

CREATE TABLE scrap_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    scrap_quantity INT NOT NULL,
    scrap_reason VARCHAR(255),
    item_condition VARCHAR(150),
    approved_by VARCHAR(150),
    scrapped_by VARCHAR(150),
    scrap_date DATE,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE SET NULL
);


CREATE TABLE invoice_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    po_number VARCHAR(100),
    invoice_number VARCHAR(100),
    supplier_name VARCHAR(150),
    file_name VARCHAR(255),
    file_path VARCHAR(500),
    json_metadata TEXT,
    invoice_amount DECIMAL(10,2),
    payment_status VARCHAR(50) DEFAULT 'Pending',
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_document_id INT,
    supplier_name VARCHAR(150),
    paid_amount DECIMAL(10,2),
    payment_status VARCHAR(50),
    payment_date DATE,
    transaction_reference VARCHAR(150),
    remarks TEXT,
    FOREIGN KEY(invoice_document_id) REFERENCES invoice_documents(id) ON DELETE SET NULL
);

INSERT INTO users(username,password,full_name,email,role,address) VALUES
('admin','admin123','Administrator','admin@bsiet.in','admin','Dr. Bapuji Salunkhe Institute of Engineering and Technology, Kolhapur'),
('director','director123','Director','director@bsiet.in','director','Dr. Bapuji Salunkhe Institute of Engineering and Technology, Kolhapur'),
('store','store123','Store Officer','store@bsiet.in','store','Dr. Bapuji Salunkhe Institute of Engineering and Technology, Kolhapur'),
('deptuser','user123','Department User','user@bsiet.in','user','Dr. Bapuji Salunkhe Institute of Engineering and Technology, Kolhapur');


INSERT INTO categories(category_name,description) VALUES
('Tech','Technology Products'),('Fashion','Fashion Related Products'),('Electronic','Electronic Equipment'),('Stationery','Office and academic stationery');

INSERT INTO suppliers(name,email,phone,address) VALUES
('AGC','agc@gmail.com','88827837778','Main Street'),
('B Group','info@bgroup.com','778777387','Main Street'),
('HP Group','info@hpgroup.com','3333333343','Main Street');

INSERT INTO products(name,description,category,supplier,price,quantity,status) VALUES
('Mouse','Computer Mouse','Tech','HP Group',850.00,20,'In Stock'),
('Hair Oil','Hair Product','Fashion','AGC',150.00,20,'In Stock'),
('LED Light','LED Product','Electronic','B Group',450.00,5,'Low Stock'),
('PC','Desktop Computer','Tech','HP Group',40000.00,3,'Low Stock'),
('Cream','Skin Product','Fashion','B Group',120.00,12,'In Stock'),
('RAM','Computer RAM','Tech','HP Group',1800.00,2,'Low Stock'),
('Screen 1','Display Screen','Electronic','HP Group',7000.00,0,'Out of Stock'),
('Monitor','Computer Monitor','Electronic','B Group',25000.00,3,'Low Stock');

INSERT INTO departments(department_name,contact_person,remarks) VALUES
('Computer Science','CSE Store Coordinator','Department receiving and requirement records'),
('Mechanical','Mechanical Store Coordinator','Workshop and laboratory requirements'),
('Electrical','Electrical Store Coordinator','Electrical laboratory requirements'),
('Civil','Civil Store Coordinator','Civil laboratory and office requirements'),
('Office Administration','Office Superintendent','Office and stationery requirements');

INSERT INTO requirements(department_name,requested_by,item_name,quantity,purpose,request_date,status) VALUES
('Computer Science','Dr. Rajendra Bhosale','Desktop Computers',5,'Lab Upgradation',CURDATE(),'Pending'),
('Mechanical','Prof. Patil','Projector',2,'Seminar Hall',CURDATE(),'Approved');

INSERT INTO approvals(requirement_id,approved_by,approval_status,remarks,approval_date) VALUES
(2,'Director','Approved','Approved for purchase',CURDATE());

INSERT INTO purchase_orders(po_number,requirement_id,supplier_id,supplier_name,po_date,total_amount,po_status) VALUES
('PO-2026-001',2,2,'B Group',CURDATE(),50000.00,'Generated');

INSERT INTO received_items(po_id,product_id,received_quantity,received_by,receive_date,remarks) VALUES
(1,8,2,'Store Admin',CURDATE(),'Received successfully');

INSERT INTO item_transfers(product_id,department_id,requirement_id,transfer_quantity,transfer_type,issued_to,issued_by,transfer_date,remarks) VALUES
(1,1,NULL,2,'Issue','CSE Lab','Store Admin',CURDATE(),'Issued as a set of two mouse units for lab use'),
(8,1,2,1,'Issue','Seminar Hall','Store Admin',CURDATE(),'Issued one monitor against approved requirement');

INSERT INTO scrap_items(product_id,scrap_quantity,scrap_reason,item_condition,approved_by,scrapped_by,scrap_date,remarks) VALUES
(7,1,'Display not working','Unusable','Director','Store Admin',CURDATE(),'Moved to scrap after verification');

INSERT INTO invoice_documents(po_number,invoice_number,supplier_name,file_name,file_path,json_metadata,invoice_amount,payment_status) VALUES
('PO-2026-001','INV-2026-001','B Group','sample_invoice.pdf','uploads/invoices/sample_invoice.pdf','{"po_number":"PO-2026-001","invoice_number":"INV-2026-001","supplier_name":"B Group","file_name":"sample_invoice.pdf","file_path":"uploads/invoices/sample_invoice.pdf","invoice_amount":50000,"payment_status":"Partial Payment"}',50000.00,'Partial Payment');

INSERT INTO payments(invoice_document_id,supplier_name,paid_amount,payment_status,payment_date,transaction_reference,remarks) VALUES
(1,'B Group',25000.00,'Partial Payment',CURDATE(),'TXN998877','Advance payment released');

SHOW TABLES;
