
SET FOREIGN_KEY_CHECKS=0;

DELETE FROM core_person WHERE person_id LIKE '100266%' OR person_id LIKE  "134807%" OR person_id LIKE  "134844%";
DELETE FROM person WHERE person_id LIKE '100266%' OR person_id LIKE  "134807%"  OR person_id LIKE  "134844%";
DELETE FROM person_addresses WHERE person_id LIKE '100266%' OR person_id LIKE  "134807%"  OR person_id LIKE  "134844%";
DELETE FROM person_attributes WHERE person_id LIKE '100266%' OR person_id LIKE  "134807%"  OR person_id LIKE  "134844%";
DELETE FROM person_birth_details WHERE person_id LIKE '100266%' OR person_id LIKE  "134807%"  OR person_id LIKE  "134844%";
DELETE FROM person_identifiers WHERE person_id LIKE '100266%' OR person_id LIKE  "134807%"  OR person_id LIKE  "134844%";
DELETE FROM person_name WHERE person_id LIKE '100266%' OR person_id LIKE  "134807%"  OR person_id LIKE  "134844%";
DELETE FROM person_name_code WHERE person_name_code_id LIKE '100266%' OR person_name_code_id LIKE  "134807%"  OR person_name_code_id LIKE  "134844%";
DELETE FROM person_record_statuses WHERE person_id LIKE '100266%' OR person_id LIKE  "134807%"  OR person_id LIKE  "134844%";
DELETE FROM potential_duplicates WHERE person_id LIKE '100266%' OR person_id LIKE  "134807%"  OR person_id LIKE  "134844%";
DELETE FROM users WHERE person_id LIKE '100266%' OR person_id LIKE  "134807%"  OR person_id LIKE  "134844%";
DELETE FROM user_role WHERE user_id LIKE '100266%' OR user_id LIKE  "134807%"  OR user_id LIKE  "134844%";
DELETE FROM notification WHERE person_id LIKE '100266%' OR person_id LIKE  "134807%"  OR person_id LIKE  "134844%";
DELETE FROM audit_trails WHERE person_id LIKE '100266%' OR person_id LIKE  "134807%"  OR person_id LIKE  "134844%";
DELETE FROM duplicate_records WHERE person_id LIKE '100266%' OR person_id LIKE  "134807%"  OR person_id LIKE  "134844%";
DELETE FROM person_relationship WHERE person_relationship_id LIKE '100266%' OR person_relationship_id LIKE  "134807%"  OR person_relationship_id LIKE  "134844%";

SET FOREIGN_KEY_CHECKS=1;

