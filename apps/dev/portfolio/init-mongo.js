const dbName="dbname";
const collections= ["gh", "gr", "sch"];
const db = db.getSiblingDB(dbName);
collections.forEach((collection)=>{
    db.createCollection(collection);
});
