#EcommerceApp with Flutter-Postgresql-SUPABASE 


<p float="left">
  <img src="https://github.com/user-attachments/assets/ec3adab4-5f5a-4949-8c9f-0ceaf07df377" width="30%" />
  <img src="https://github.com/user-attachments/assets/f275a1c0-959f-4367-a180-e181ea3b9ec9" width="30%" />
  <img src="https://github.com/user-attachments/assets/1ee6d377-9ef0-4f6b-b580-60f8d611c62c" width="30%" />
</p>

<p float="left">
  <img src="https://github.com/user-attachments/assets/a358bb2b-ecf1-41f0-91fe-fcc9f9f6b48a" width="30%" />
  <img src="https://github.com/user-attachments/assets/6909dc2e-934a-4763-adba-7d0bcf588053" width="30%" />
  <img src="https://github.com/user-attachments/assets/92735d56-150f-4ed4-b993-35df6cc92ae7" width="30%" />
</p>

 
 

PostgreSql
sql codes: 
<code>
create table products (

  id          serial primary key,
  name        text        not null,
  description text,
  price       numeric(10,2) not null,
  image_url   text

);


create table carts (
  id          serial primary key,
  user_id     uuid        not null,
  created_at  timestamptz default now()
);
create table cart_items (

  id          serial primary key,
  cart_id     integer     references carts(id),
  product_id  integer     references products(id),
  quantity    integer     default 1

);

create table orders (

  id          serial primary key,
  user_id     uuid      not null,
  total       numeric(10,2),
  created_at  timestamptz default now()

);

create table order_items (

  id          serial primary key,
  order_id    integer    references orders(id),
  product_id  integer    references products(id),
  quantity    integer    not null

);
</code>
