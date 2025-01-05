# Simple Inventory Management System with Zenity
![linux](https://github.com/user-attachments/assets/70c25852-5a5d-4f0c-8164-2d4f96351daf)
## **About the project**
Hello Everyone
- I am Suleyman Asim Gelisgen. I am student at Bursa Technical University department of computer sience.
* Today I will tell you about my linux shell project. Before I start, I would like to thank Prof. Dr. Turgay Bigin and Research Assistant Talha Koruk for their support in this project.
* This project aims to develop a simple inventory management system using Zenity tools. The system supports basic functions such as adding, listing, updating and deleting products with a user-friendly graphical interface. Additionally, features such as user and program management are also provided.
![cmatrix](https://github.com/user-attachments/assets/375c2947-9803-4bdd-800c-50694a6f2e17)
## **Features**
 ### **A)User Roles**
 * **Administrator**: Can add, update, delete products and manage users,Can view products and get reports
* **User**: Can view products and get reports.
 ### **B)Basic Functions**
 #### 1)Product Management
- Adding, listing, updating and deleting products.
- Reporting for products with decreasing stock or products with the highest stock amount.
  
#### 2)User Management
- Adding, listing, updating and deleting new users.
- Password reset and account lockout management.

#### 3)Programme Management
- Disk space display.
- Data backup.
- Reviewing error logs.

#### 4)Security and Error Management
- Recording and reporting of erroneous entries.
- User approval for critical transactions.
## **Set up**
#### 1)Set up Zenity:
```
#Zenity check
zenity --help
#Zenity installation
sudo apt install zenity

```
#### 2)Clone the project:
```
git clone https://github.com/gelisgen03/Linux-Zenity-Inventory-Management-System.git
cd Linux-Zenity-Inventory-Management-System
```
#### 3)Set executable permissions:
```
chmod +x proje.sh
```
#### 4)Run the script:
```
./proje.sh
```
## **Usage**
#### 1)Login
* Login to the system with username and password.
#### 2)Main Menu
* Add Product: Add product information with Zenity's form interface.
* List Product: View available inventory.
* Update Product: Edit the information of a selected product.
* Delete Product: Remove a specific product from the system.
* Get Report: Generate reports by analysing stock.
* User Management: Add, list, update and delete users (administrator only).
* Programme Management: Check disc space, make backups and view error logs.
#### 3)Logout
* You can exit the programme with the option at the bottom of the main menu.
## **Screenshots**
## **Video**
#### **Thanks :)**


