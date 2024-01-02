-- remove time from date

ALTER TABLE housing_data
MODIFY SaleDate date;

--  Some missing values in Property Adress - populating missing data

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, coalesce(a.PropertyAddress, b.PropertyAddress)
FROM housing_data a JOIN housing_data b ON a.ParcelID=b.ParcelID
AND a.UNIQUEID <> b.UNIQUEID
WHERE a.PropertyAddress IS NULL;

UPDATE housing_data a JOIN housing_data b 
					ON a.ParcelID=b.ParcelID
					AND a.UNIQUEID <> b.UNIQUEID
SET a.PropertyAddress = b.PropertyAddress
WHERE a.PropertyAddress IS NULL;

-- Breaking out address into separate columns, starting with PropertyAddress

SELECT PropertyAddress, SUBSTRING(PropertyAddress, 1, POSITION(',' IN PropertyAddress)-1) as Address,
				SUBSTRING(PropertyAddress, POSITION(',' IN PropertyAddress)+2) as City
FROM housing_data;

ALTER TABLE housing_data
ADD PropertyCitySplit VARCHAR(255);

UPDATE housing_data
SET PropertyCitySplit = SUBSTRING(PropertyAddress, POSITION(',' IN PropertyAddress)+2);

ALTER TABLE housing_data
ADD PropertyAddressSplit VARCHAR(255);

UPDATE housing_data
SET PropertyAddressSplit = SUBSTRING(PropertyAddress, 1, POSITION(',' IN PropertyAddress)-1);

-- Same action, different method on OwnerAddress

SELECT OwnerAddress, 
			substring_index(OwnerAddress,',',1) as Adress,
			substring_index(substring_index(OwnerAddress,',', 2),',',-1) as City,
            substring_index(OwnerAddress,',',-1) as State
FROM housing_data;

ALTER TABLE housing_data
ADD OwnerAddressSplit VARCHAR(255);

UPDATE housing_data
SET OwnerAddressSplit = substring_index(OwnerAddress,',',1);

ALTER TABLE housing_data
ADD OwnerCitySplit VARCHAR(255);

UPDATE housing_data
SET OwnerCitySplit = substring_index(substring_index(OwnerAddress,',', 2),',',-1);

ALTER TABLE housing_data
ADD OwnerStateSplit VARCHAR(255);

UPDATE housing_data
SET OwnerStateSplit = substring_index(OwnerAddress,',',-1);

-- Standardise SoldAsVacant column's data - changing N and Y to 'No' and 'Yes'

SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM housing_data
GROUP BY 1;

UPDATE housing_data
SET SoldAsVacant = 'Yes'
WHERE SoldAsVacant = 'Y';

UPDATE housing_data
SET SoldAsVacant = 'No'
WHERE SoldAsVacant = 'N';

/* Alternative way for more modifications:

UPDATE housing_data
SET SoldAsVacant = CASE
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
                        WHEN SoldAsVacant = 'N' THEN 'No'
                        ELSE SoldAsVacant
                        END;
								*/
                                
-- finding and removing duplicates
WITH cte AS (
				SELECT *,
					row_number() OVER (PARTITION BY ParcelID,
										PropertyAddress,
										SalePrice,
										SaleDate,
										LegalReference
										ORDER BY UniqueID) as row_num
					FROM housing_data
					ORDER BY parcelID)
SELECT *
FROM cte
WHERE row_num > 1;

DELETE FROM housing_data
WHERE uniqueID IN 
			(SELECT uniqueID FROM 
								(SELECT *,
										row_number() OVER (PARTITION BY ParcelID,
											PropertyAddress,
											SalePrice,
											SaleDate,
											LegalReference
											ORDER BY UniqueID) as row_num
                                            FROM housing_data) t
			WHERE row_num > 1);

-- getting rid off unnecessary columns

ALTER TABLE housing_data
DROP COLUMN OwnerAddress, 
DROP COLUMN PropertyAddress, 
DROP COLUMN TaxDistrict;

select * from housing_data;

