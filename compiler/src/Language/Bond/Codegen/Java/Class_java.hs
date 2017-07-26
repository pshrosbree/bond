-- Copyright (c) Microsoft. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root
-- for full license information.

{-# LANGUAGE QuasiQuotes, OverloadedStrings, RecordWildCards #-}

module Language.Bond.Codegen.Java.Class_java
    ( class_java
    , JavaFieldMapping(..)
    ) where

import Prelude
import Data.Text.Lazy (Text)
import Text.Shakespeare.Text
import Language.Bond.Syntax.Types
import Language.Bond.Syntax.Util
import Language.Bond.Util
import Language.Bond.Codegen.TypeMapping
import Language.Bond.Codegen.Util
import Language.Bond.Codegen.Java.Util


-- field -> public field
data JavaFieldMapping = JavaPublicFields deriving Eq


-- given the type of the field, returns the name of the struct field descriptor type (a protected nested class within StructBondType)
structFieldDescriptorTypeName :: MappingContext -> Type -> Text
structFieldDescriptorTypeName java = typeName
    where
        typeName (BT_Maybe BT_Int8) = [lt|com.microsoft.bond.StructBondType.SomethingInt8StructField|]
        typeName BT_Int8 = [lt|com.microsoft.bond.StructBondType.Int8StructField|]
        typeName (BT_Maybe BT_Int16) = [lt|com.microsoft.bond.StructBondType.SomethingInt16StructField|]
        typeName BT_Int16 = [lt|com.microsoft.bond.StructBondType.Int16StructField|]
        typeName (BT_Maybe BT_Int32) = [lt|com.microsoft.bond.StructBondType.SomethingInt32StructField|]
        typeName BT_Int32 = [lt|com.microsoft.bond.StructBondType.Int32StructField|]
        typeName (BT_Maybe BT_Int64) = [lt|com.microsoft.bond.StructBondType.SomethingInt64StructField|]
        typeName BT_Int64 = [lt|com.microsoft.bond.StructBondType.Int64StructField|]
        typeName (BT_Maybe BT_UInt8) = [lt|com.microsoft.bond.StructBondType.SomethingUInt8StructField|]
        typeName BT_UInt8 = [lt|com.microsoft.bond.StructBondType.UInt8StructField|]
        typeName (BT_Maybe BT_UInt16) = [lt|com.microsoft.bond.StructBondType.SomethingUInt16StructField|]
        typeName BT_UInt16 = [lt|com.microsoft.bond.StructBondType.UInt16StructField|]
        typeName (BT_Maybe BT_UInt32) = [lt|com.microsoft.bond.StructBondType.SomethingUInt32StructField|]
        typeName BT_UInt32 = [lt|com.microsoft.bond.StructBondType.UInt32StructField|]
        typeName (BT_Maybe BT_UInt64) = [lt|com.microsoft.bond.StructBondType.SomethingUInt64StructField|]
        typeName BT_UInt64 = [lt|com.microsoft.bond.StructBondType.UInt64StructField|]
        typeName (BT_Maybe BT_Float) = [lt|com.microsoft.bond.StructBondType.SomethingFloatStructField|]
        typeName BT_Float = [lt|com.microsoft.bond.StructBondType.FloatStructField|]
        typeName (BT_Maybe BT_Double) = [lt|com.microsoft.bond.StructBondType.SomethingDoubleStructField|]
        typeName BT_Double = [lt|com.microsoft.bond.StructBondType.DoubleStructField|]
        typeName (BT_Maybe BT_Bool) = [lt|com.microsoft.bond.StructBondType.SomethingBoolStructField|]
        typeName BT_Bool = [lt|com.microsoft.bond.StructBondType.BoolStructField|]
        typeName (BT_Maybe BT_String) = [lt|com.microsoft.bond.StructBondType.SomethingStringStructField|]
        typeName BT_String = [lt|com.microsoft.bond.StructBondType.StringStructField|]
        typeName (BT_Maybe BT_WString) = [lt|com.microsoft.bond.StructBondType.SomethingWStringStructField|]
        typeName BT_WString = [lt|com.microsoft.bond.StructBondType.WStringStructField|]
        typeName (BT_Maybe (BT_UserDefined e@Enum {} _)) = [lt|com.microsoft.bond.StructBondType.SomethingEnumStructField<#{qualifiedDeclaredTypeName java e}>|]
        typeName (BT_UserDefined e@Enum {} _) = [lt|com.microsoft.bond.StructBondType.EnumStructField<#{qualifiedDeclaredTypeName java e}>|]
        typeName (BT_Maybe t) = [lt|com.microsoft.bond.StructBondType.SomethingObjectStructField<#{(getTypeName java) t}>|]
        typeName t = [lt|com.microsoft.bond.StructBondType.ObjectStructField<#{(getTypeName java) t}>|]


-- given the type of the field, value indicating whether a struct field descriptor type is generic and hence needs an explicit type parameter
isGenericStructFieldDescriptor :: Type -> Bool
isGenericStructFieldDescriptor (BT_Maybe t) = not (isPrimitiveNonEnumBondType t)
isGenericStructFieldDescriptor t = not (isPrimitiveNonEnumBondType t)


-- given a type parameter, returns the name of a local variable containing the type descriptor
typeParamVarName :: TypeParam -> Text
typeParamVarName TypeParam {..} = [lt|#{paramName}|]


-- given a type parameter, returns the declaration of a local variable containing the type descriptor
typeParamVarDecl :: TypeParam -> Text
typeParamVarDecl t@TypeParam {..} = [lt|com.microsoft.bond.BondType<#{paramName}> #{typeParamVarName t}|]


-- given a list of type parameters, returns it as comma-separated text
typeParamNameList :: [TypeParam] -> Text
typeParamNameList declParams = [lt|#{sepBy ", " paramName declParams}|]


-- given a list of type parameter, returns a comma-separated list of names of local variables containing the type descriptor
typeParamVarNameList :: [TypeParam] -> Text
typeParamVarNameList declParams = [lt|#{sepBy ", " typeParamVarName declParams}|]


-- given a list of type parameter, returns a comma-separated list of declarations of local variables containing the type descriptor
typeParamVarDeclList :: [TypeParam] -> Text
typeParamVarDeclList declParams = [lt|#{sepBy ", " typeParamVarDecl declParams}|]


-- given a list of type parameters, returns it as comma-separated text with angles (unless the list is empty)
typeParamAnglesNameList :: [TypeParam] -> Text
typeParamAnglesNameList declParams = [lt|#{angles $ typeParamNameList declParams}|]


-- given a class name and a list of type parameters, returns the full type name with type parameters (if any)
typeNameWithParams :: String -> [TypeParam] -> Text
typeNameWithParams declName declParams = [lt|#{declName}#{typeParamAnglesNameList declParams}|]


-- given a class name and a list of type parameters, returns the full type descriptor name with type parameters (if any)
typeDescriptorNameWithParams :: String -> [TypeParam] -> Text
typeDescriptorNameWithParams declName declParams = [lt|com.microsoft.bond.StructBondType<#{typeNameWithParams declName declParams}>|]


-- given a class name, returns the full type descriptor name (using non-generic notation for the struct type)
typeDescriptorName :: String -> Text
typeDescriptorName declName = [lt|com.microsoft.bond.StructBondType<#{declName}>|]


-- given a variable name, returns call to ArgumentHelper.ensureNotNull method that checks the variable for null
ensureNotNullArgument :: Text -> Text
ensureNotNullArgument argName = [lt|com.microsoft.bond.helpers.ArgumentHelper.ensureNotNull(#{argName}, "#{argName}")|]


-- given a field type and optional default value, returns an expression for the parameter containing the default value,
-- along with the leading comma; this value is used in initialization of struct field descriptors where
-- the constructors are overloaded to take explicit default value or take none (i.e. use the implicit default)
fieldDefaultValueInitParamExpr :: MappingContext -> Type -> Maybe Default -> Text
fieldDefaultValueInitParamExpr _ _ (Just (DefaultBool val)) = if val
    then [lt|, true|]
    else [lt|, false|]
fieldDefaultValueInitParamExpr _ BT_Int8 (Just (DefaultInteger val)) = [lt|, (byte)#{val}|]
fieldDefaultValueInitParamExpr _ BT_Int16 (Just (DefaultInteger val)) = [lt|, (short)#{val}|]
fieldDefaultValueInitParamExpr _ BT_Int32 (Just (DefaultInteger val)) = [lt|, #{val}|]
fieldDefaultValueInitParamExpr _ BT_Int64 (Just (DefaultInteger val)) = [lt|, #{val}L|]
fieldDefaultValueInitParamExpr _ BT_UInt8 (Just (DefaultInteger val)) = [lt|, (byte)#{val}|]
fieldDefaultValueInitParamExpr _ BT_UInt16 (Just (DefaultInteger val)) = [lt|, (short)#{val}|]
fieldDefaultValueInitParamExpr _ BT_UInt32 (Just (DefaultInteger val)) = [lt|, #{val}|]
fieldDefaultValueInitParamExpr _ BT_UInt64 (Just (DefaultInteger val)) = [lt|, #{val}L|]
fieldDefaultValueInitParamExpr _ BT_Float (Just (DefaultFloat val)) = [lt|, #{val}F|]
fieldDefaultValueInitParamExpr _ BT_Float (Just (DefaultInteger val)) = [lt|, #{val}F|]
fieldDefaultValueInitParamExpr _ BT_Double (Just (DefaultFloat val)) = [lt|, #{val}D|]
fieldDefaultValueInitParamExpr _ BT_Double (Just (DefaultInteger val)) = [lt|, #{val}D|]
fieldDefaultValueInitParamExpr _ BT_String (Just (DefaultString val)) = [lt|, "#{val}"|]
fieldDefaultValueInitParamExpr _ BT_WString (Just (DefaultString val)) = [lt|, "#{val}"|]
fieldDefaultValueInitParamExpr java (BT_UserDefined e@Enum {..} _) (Just (DefaultEnum val)) = [lt|, #{qualifiedDeclaredTypeName java e}.#{val}|]
fieldDefaultValueInitParamExpr _ _ _ = mempty


-- given a struct name and type parameters, and type, returns a type descriptor expression for the field, used in initialization of struct field descriptors
structFieldDescriptorInitStructExpr :: MappingContext -> Type -> String -> [Type] -> Text
structFieldDescriptorInitStructExpr java fieldType typeName params = [lt|#{typeCastExpr} getStructType(#{typeName}.class#{paramExprList params})|]
    where
        typeCastExpr = [lt|(com.microsoft.bond.StructBondType<#{(getTypeName java) fieldType}>)|]
        paramExprList :: [Type] -> Text
        paramExprList [] = mempty
        paramExprList (x:xs) = [lt|, #{structFieldDescriptorInitTypeExpr java x}#{paramExprList xs}|]


-- given field type, returns a type descriptor expression for the field, used in initialization of struct field descriptors
structFieldDescriptorInitTypeExpr :: MappingContext -> Type -> Text
structFieldDescriptorInitTypeExpr java (BT_Maybe t) = structFieldDescriptorInitTypeExpr java t
structFieldDescriptorInitTypeExpr _ BT_Int8 = [lt|com.microsoft.bond.BondTypes.INT8|]
structFieldDescriptorInitTypeExpr _ BT_Int16 = [lt|com.microsoft.bond.BondTypes.INT16|]
structFieldDescriptorInitTypeExpr _ BT_Int32 = [lt|com.microsoft.bond.BondTypes.INT32|]
structFieldDescriptorInitTypeExpr _ BT_Int64 = [lt|com.microsoft.bond.BondTypes.INT64|]
structFieldDescriptorInitTypeExpr _ BT_UInt8 = [lt|com.microsoft.bond.BondTypes.UINT8|]
structFieldDescriptorInitTypeExpr _ BT_UInt16 = [lt|com.microsoft.bond.BondTypes.UINT16|]
structFieldDescriptorInitTypeExpr _ BT_UInt32 = [lt|com.microsoft.bond.BondTypes.UINT32|]
structFieldDescriptorInitTypeExpr _ BT_UInt64 = [lt|com.microsoft.bond.BondTypes.UINT64|]
structFieldDescriptorInitTypeExpr _ BT_Float = [lt|com.microsoft.bond.BondTypes.FLOAT|]
structFieldDescriptorInitTypeExpr _ BT_Double = [lt|com.microsoft.bond.BondTypes.DOUBLE|]
structFieldDescriptorInitTypeExpr _ BT_Bool = [lt|com.microsoft.bond.BondTypes.BOOL|]
structFieldDescriptorInitTypeExpr _ BT_String = [lt|com.microsoft.bond.BondTypes.STRING|]
structFieldDescriptorInitTypeExpr _ BT_WString = [lt|com.microsoft.bond.BondTypes.WSTRING|]
structFieldDescriptorInitTypeExpr _ BT_Blob = [lt|com.microsoft.bond.BondTypes.BLOB|]
structFieldDescriptorInitTypeExpr java (BT_Bonded t) = [lt|bondedOf(#{structFieldDescriptorInitTypeExpr java t})|]
structFieldDescriptorInitTypeExpr java (BT_Nullable t) = [lt|nullableOf(#{structFieldDescriptorInitTypeExpr java t})|]
structFieldDescriptorInitTypeExpr java (BT_Vector t) = [lt|vectorOf(#{structFieldDescriptorInitTypeExpr java t})|]
structFieldDescriptorInitTypeExpr java (BT_List t) = [lt|listOf(#{structFieldDescriptorInitTypeExpr java t})|]
structFieldDescriptorInitTypeExpr java (BT_Set t) = [lt|setOf(#{structFieldDescriptorInitTypeExpr java t})|]
structFieldDescriptorInitTypeExpr java (BT_Map k v) = [lt|mapOf(#{structFieldDescriptorInitTypeExpr java k}, #{structFieldDescriptorInitTypeExpr java v})|]
structFieldDescriptorInitTypeExpr _ (BT_TypeParam param) = [lt|#{paramName param}|]
structFieldDescriptorInitTypeExpr java (BT_UserDefined e@Enum {} _) = [lt|#{qualifiedDeclaredTypeName java e}.BOND_TYPE|]
structFieldDescriptorInitTypeExpr java t@(BT_UserDefined s@Struct {} params) = [lt|#{structFieldDescriptorInitStructExpr java t (qualifiedDeclaredTypeName java s) params}|]
structFieldDescriptorInitTypeExpr java t@(BT_UserDefined s@Forward {} params) = [lt|#{structFieldDescriptorInitStructExpr java t (qualifiedDeclaredTypeName java s) params}|]
structFieldDescriptorInitTypeExpr java t@(BT_UserDefined a@Alias {} params) = structFieldDescriptorInitTypeExpr java (resolveAlias a params)
structFieldDescriptorInitTypeExpr _ t = error $ "invalid declaration type for structFieldDescriptorInitTypeExpr: " ++ show t


-- given struct base type, returns a type descriptor expression
structBaseDescriptorInitStructExpr :: MappingContext -> Maybe Type -> Text
structBaseDescriptorInitStructExpr java t = maybe [lt|null|] (structFieldDescriptorInitTypeExpr java) t


-- given struct class name and generic type parameters, builds text for GenericBondTypeBuilder abstract class
-- that defines the public API to specialize a generic struct to specific generic type arguments
-- (this class is generated only when the enclosing Bond struct class is generic)
makeStructMember_GenericBondTypeBuilder :: String -> [TypeParam] -> Text
makeStructMember_GenericBondTypeBuilder declName declParams = [lt|
    public static abstract class GenericBondTypeBuilder {

        private GenericBondTypeBuilder() {
        }

        public abstract #{typeParamAnglesNameList declParams} #{typeDescriptorNameWithParams declName declParams} makeGenericType(#{typeParamVarDeclList declParams});
    }
|]


-- given struct class name and generic type parameters, builds text for implementation
-- of the StructBondTypeBuilderImpl.makeGenericType method
-- (this method is generated only when the enclosing Bond struct class is generic)
makeStructBuilderMember_makeGenericType :: String -> [TypeParam] -> Text
makeStructBuilderMember_makeGenericType declName declParams = [lt|
            private #{typeParamAnglesNameList declParams} #{typeDescriptorNameWithParams declName declParams} makeGenericType(#{typeParamVarDeclList declParams}) {
                #{newlineSepEnd 4 checkArg declParams}return #{castExpr} this.getInitializedFromCache(#{typeParamVarNameList declParams});
            }
|]
    where
        checkArg t@TypeParam {..} = [lt|#{ensureNotNullArgument (typeParamVarName t)};|]
        castExpr = [lt|(StructBondTypeImpl)|]


-- given struct class name and generic type parameters, builds text for implementation of
-- the StructBondTypeBuilderImpl class which is responsible for building the type descriptor
makeStructBondTypeMember_StructBondTypeBuilderImpl :: String -> [TypeParam] -> Text
makeStructBondTypeMember_StructBondTypeBuilderImpl declName declParams = [lt|
        static final class StructBondTypeBuilderImpl extends com.microsoft.bond.StructBondType.StructBondTypeBuilder<#{declName}> {
            #{ifThenElse (null declParams) mempty (makeStructBuilderMember_makeGenericType declName declParams)}
            @Override
            public final int getGenericTypeParameterCount() {
                return #{length declParams};
            }

            @Override
            protected final #{typeDescriptorName declName} buildNewInstance(com.microsoft.bond.BondType[] genericTypeArguments) {
                return new StructBondTypeImpl(#{ifThenElse (null declParams) "null" "new com.microsoft.bond.GenericTypeSpecialization(genericTypeArguments)"});
            }

            static void register() {
                registerStructType(#{declName}.class, new StructBondTypeBuilderImpl());
            }
        }|]


-- given generic type parameters, struct fields, and base type, builds text for implementation of
-- the StructBondTypeImpl.initialize method
makeStructBondTypeMember_initialize :: MappingContext -> [TypeParam] -> [Field] -> Maybe Type -> Text
makeStructBondTypeMember_initialize java declParams structFields structBase = [lt|
        @Override
        protected final void initialize() {#{typeArgVarDeclList}#{fieldDescriptorInitList}
            super.initializeBaseAndFields(#{baseTypeDescriptorParam}#{fieldTypeDescriptorParamsSeparator}#{fieldTypeDescriptorParams});
        }|]
    where
        typeArgVarDeclList = newlineBeginSep 3 typeArgVarDecl indexedDeclParams
        typeArgVarDecl (index, typeParam) = [lt|#{typeParamVarDecl typeParam} = this.getGenericSpecialization().getGenericTypeArgument(#{index});|]
        indexedDeclParams = zip [0 :: Int ..] declParams

        fieldDescriptorInitList = newlineBeginSep 3 fieldDescriptorInit structFields
        fieldDescriptorInit Field {..} = [lt|this.#{fieldName} = new #{structFieldDescriptorTypeName java fieldType}(#{constructorParams});|]
          where
            constructorParams = [lt|this#{fieldTypeParam}, #{fieldOrdinal}, "#{fieldName}", #{modifierConstantName fieldModifier}#{fieldDefaultValueParam}|]
            fieldTypeParam = if isGenericStructFieldDescriptor fieldType
                then [lt|, #{structFieldDescriptorInitTypeExpr java fieldType}|]
                else mempty
            fieldDefaultValueParam = fieldDefaultValueInitParamExpr java fieldType fieldDefault

        baseTypeDescriptorParam = structBaseDescriptorInitStructExpr java structBase
        fieldTypeDescriptorParamsSeparator = ifThenElse (null structFields) mempty [lt|, |]
        fieldTypeDescriptorParams = sepBy ", " structFieldReference structFields
        structFieldReference Field {..} = [lt|this.#{fieldName}|]


-- given struct class name, generic type parameters, and struct fields, builds text for implementation of
-- the StructBondTypeImpl.serializeStructFields method
makeStructBondTypeMember_serializeStructFields :: String -> [TypeParam] -> [Field] -> Text
makeStructBondTypeMember_serializeStructFields declName declParams structFields = [lt|
        @Override
        protected final void serializeStructFields(#{methodParamDecl}) throws java.io.IOException {#{newlineBeginSep 3 serializeField structFields}
        }|]
            where
                methodParamDecl = [lt|com.microsoft.bond.BondType.SerializationContext context, #{typeNameWithParams declName declParams} value|]
                serializeField Field {..} = [lt|this.#{fieldName}.serialize(context, value.#{fieldName});|]


-- given struct class name, generic type parameters, and struct fields, builds text for implementation of
-- the StructBondTypeImpl.deserializeStructFields method
makeStructBondTypeMember_deserializeStructFields :: String -> [TypeParam] -> [Field] -> Text
makeStructBondTypeMember_deserializeStructFields declName declParams structFields = [lt|
        @Override
        protected final void deserializeStructFields(#{methodParamDecl}) throws java.io.IOException {#{newlineBeginSep 3 declareLocalVariable structFields}
            while (this.readField(context)) {
                switch (context.readFieldResult.id) {#{newlineBeginSep 5 deserializeField structFields}
                }
            }#{newlineBeginSep 3 verifyField structFields}
        }|]
            where
                methodParamDecl = [lt|com.microsoft.bond.BondType.TaggedDeserializationContext context, #{typeNameWithParams declName declParams} value|]
                declareLocalVariable Field {..} = [lt|boolean __has_#{fieldName} = false;|]
                deserializeField Field {..} = [lt|#{switchCasePart}#{newLine 6}#{deserializePart}#{newLine 6}#{setBooleanPart}#{newLine 6}break;|]
                  where
                    switchCasePart = [lt|case #{fieldOrdinal}:|]
                    deserializePart = [lt|value.#{fieldName} = this.#{fieldName}.deserialize(context, __has_#{fieldName});|]
                    setBooleanPart = [lt|__has_#{fieldName} = true;|]

                verifyField Field {..} = [lt|this.#{fieldName}.verifyDeserialized(__has_#{fieldName});|]


-- given class name, generic type parameters, and struct fields, builds text for implementation of
-- the StructBondTypeImpl.initializeStructFields method
makeStructBondTypeMember_initializeStructFields :: String -> [TypeParam] -> [Field] -> Text
makeStructBondTypeMember_initializeStructFields declName declParams structFields = [lt|
        @Override
        protected final void initializeStructFields(#{methodParamDecl}) {#{newlineBeginSep 3 initializeField structFields}
        }|]
            where
                methodParamDecl = [lt|#{typeNameWithParams declName declParams} value|]
                initializeField Field {..} = [lt|value.#{fieldName} = this.#{fieldName}.initialize();|]


-- given class name, generic type parameters, and struct fields, builds text for implementation of
-- the StructBondTypeImpl.copyStructFields method
makeStructBondTypeMember_cloneStructFields :: String -> [TypeParam] -> [Field] -> Text
makeStructBondTypeMember_cloneStructFields declName declParams structFields = [lt|
        @Override
        protected final void cloneStructFields(#{methodParamDecl}) {#{newlineBeginSep 3 cloneField structFields}
        }|]
            where
                methodParamDecl = [lt|#{typeNameWithParams declName declParams} fromValue, #{typeNameWithParams declName declParams} toValue|]
                cloneField Field {..} = [lt|toValue.#{fieldName} = this.#{fieldName}.clone(fromValue.#{fieldName});|]


-- builds text for anonymous implementation of the GenericBondTypeBuilder abstract class and assignment to the BOND_TYPE variable
bondTypeStaticVariableDeclAsGenericBondTypeBuilder :: String -> [TypeParam] -> Text
bondTypeStaticVariableDeclAsGenericBondTypeBuilder declName declParams = [lt|public static final GenericBondTypeBuilder BOND_TYPE = new GenericBondTypeBuilder() {

        final StructBondTypeImpl.StructBondTypeBuilderImpl builder = new StructBondTypeImpl.StructBondTypeBuilderImpl();

        @Override
        public final <#{paramList}> com.microsoft.bond.StructBondType<#{declName}<#{paramList}>> makeGenericType(#{sepBy ", " methodArg declParams}) {
            return this.builder.makeGenericType(#{paramList});
        }
    };|]
    where
        paramList = sepBy ", " paramName declParams
        methodArg TypeParam {..} = [lt|com.microsoft.bond.BondType<#{paramName}> #{paramName}|]


-- builds text for public constructor of non-generic Bond struct class
publicConstructorDeclForNonGenericStruct :: MappingContext -> String -> Maybe Type -> Text
publicConstructorDeclForNonGenericStruct java declName maybeBase = [lt|
    public #{declName}() {
        super(#{superConstructorArgs maybeBase});
        ((StructBondTypeImpl)BOND_TYPE).initializeStructFields(this);
    };
|]
    where
        superConstructorArgs Nothing = mempty
        superConstructorArgs (Just t) = if isGenericBondStructType t
            then [lt|(com.microsoft.bond.StructBondType<#{getTypeName java t}>)BOND_TYPE.getBaseStructType()|]
            else mempty


-- builds text for public constructor of generic Bond struct class
publicConstructorDeclForGenericStruct :: MappingContext -> String -> [TypeParam] -> Maybe Type -> Text
publicConstructorDeclForGenericStruct java declName declParams maybeBase = [lt|
public #{declName}(com.microsoft.bond.StructBondType<#{declName}<#{paramList}>> genericType) {
        super(#{superConstructorArgs maybeBase});
        this.__genericType = (StructBondTypeImpl<#{paramList}>)genericType;
        this.__genericType.initializeStructFields(this);
    };
|]
    where
        paramList = sepBy ", " paramName declParams
        superConstructorArgs Nothing = mempty
        superConstructorArgs (Just t) = if isGenericBondStructType t
            then [lt|(com.microsoft.bond.StructBondType<#{getTypeName java t}>)com.microsoft.bond.helpers.ArgumentHelper.ensureNotNull(genericType, "genericType").getBaseStructType()|]
            else mempty


-- Template for struct -> Java class.
class_java :: MappingContext -> [Import] -> Declaration -> Text
class_java java _ declaration = [lt|
package #{javaPackage};
#{typeDefinition declaration}
|]
    where
        javaType = getTypeName java
        javaPackage = sepBy "." toText $ getNamespace java

        -- struct -> Java class
        typeDefinition Struct {..} = [lt|
#{generatedClassAnnotations}
public class #{typeNameWithParams declName declParams}#{maybe interface baseClass structBase} {
    #{ifThenElse (null declParams) mempty (makeStructMember_GenericBondTypeBuilder declName declParams)}
    private static final class StructBondTypeImpl#{typeParamAnglesNameList declParams} extends #{typeDescriptorNameWithParams declName declParams} {
        #{makeStructBondTypeMember_StructBondTypeBuilderImpl declName declParams}

        #{doubleLineSep 2 fieldDescriptorFieldDecl structFields}

        private StructBondTypeImpl(com.microsoft.bond.GenericTypeSpecialization genericTypeSpecialization) {
            super(genericTypeSpecialization);
        }
        #{makeStructBondTypeMember_initialize java declParams structFields structBase}

        @Override
        public final java.lang.Class<#{typeNameWithParams declName declParams}> getValueClass() {
            return (java.lang.Class<#{typeNameWithParams declName declParams}>) (java.lang.Class) #{declName}.class;
        }

        @Override
        public final #{typeNameWithParams declName declParams} newInstance() {
            return new #{typeNameWithParams declName declParams}(#{ifThenElse (null declParams) mempty "this"});
        }
        #{makeStructBondTypeMember_serializeStructFields declName declParams structFields}
        #{makeStructBondTypeMember_deserializeStructFields declName declParams structFields}
        #{makeStructBondTypeMember_initializeStructFields declName declParams structFields}
        #{makeStructBondTypeMember_cloneStructFields declName declParams structFields}
    }

    #{bondTypeStaticVariableDecl}

    public static void initializeBondType() {
        StructBondTypeImpl.StructBondTypeBuilderImpl.register();
    }

    static {
        initializeBondType();
    }
    #{bondTypeDescriptorInstanceVariableDecl}

    #{doubleLineSep 1 publicFieldDecl structFields}
    #{publicConstructorDecl}

    @Override
    public com.microsoft.bond.StructBondType<? extends #{typeNameWithParams declName declParams}> getBondType() {
        return #{getBondTypeReturnValue};
    }
}|]
            where
                interface = [lt| implements com.microsoft.bond.BondSerializable|]
                baseClass x = [lt| extends #{javaType x}|]
                publicFieldDecl Field {..} = [lt|public #{javaType fieldType} #{fieldName};|]
                fieldDescriptorFieldDecl Field {..} = [lt|private #{structFieldDescriptorTypeName java fieldType} #{fieldName};|]
                bondTypeStaticVariableDecl = if null declParams
                    then [lt|public static final com.microsoft.bond.StructBondType<#{declName}> BOND_TYPE = new StructBondTypeImpl.StructBondTypeBuilderImpl().getInitializedFromCache();|]
                    else bondTypeStaticVariableDeclAsGenericBondTypeBuilder declName declParams
                bondTypeDescriptorInstanceVariableDecl = if null declParams
                    then mempty
                    else [lt|private final StructBondTypeImpl#{typeParamAnglesNameList declParams} __genericType;|]
                getBondTypeReturnValue = if null declParams
                    then [lt|BOND_TYPE|]
                    else [lt|this.__genericType|]
                publicConstructorDecl = if null declParams
                    then publicConstructorDeclForNonGenericStruct java declName structBase
                    else publicConstructorDeclForGenericStruct java declName declParams structBase

        typeDefinition _ = mempty