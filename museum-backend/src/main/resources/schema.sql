create table if not exists exhibitions (
    id varchar(36) primary key,
    title varchar(100) not null,
    artwork_ids varchar(500) not null
);
