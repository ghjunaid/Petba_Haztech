<?php

use App\Http\Controllers\FosterController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AddressController;
use App\Http\Controllers\AdoptionController;
use App\Http\Controllers\AnimalController;
use App\Http\Controllers\APIController;
use App\Http\Controllers\AuthorisationController;
use App\Http\Controllers\CartController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\ChatController;
use App\Http\Controllers\ColorController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\FilterController;
use App\Http\Controllers\InterestController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\SupportController;
use App\Http\Controllers\WishlistController;
use App\Http\Controllers\PetController;
use App\Http\Controllers\RescuePetController;
use App\Http\Controllers\TokenController;
use App\Http\Controllers\BlogController;
use App\Http\Controllers\CityController;
use App\Http\Controllers\GroomingController;
use App\Http\Controllers\ShelterController;
use App\Http\Controllers\TrainerController;
use App\Http\Controllers\VetController;
use App\Http\Controllers\DonationController;

// missing routes ['getfcmtoken', 'sendfcm']

Route::post('login', [AuthorisationController::class, 'login']);          
Route::post('register', [AuthorisationController::class, 'signup']);      
Route::post('passwordCheck', [AuthorisationController::class, 'passwordCheck']);      
Route::post('changePassword', [AuthorisationController::class, 'changePassword']);    
Route::post('checkAccount', [AuthorisationController::class, 'checkAccount']);        
Route::post('/firstname', [AuthorisationController::class, 'firstname']);             
Route::post('/updateProfilePic', [AuthorisationController::class, 'updateProfilePic']);     
Route::post('/customerdata', [AuthorisationController::class, 'customerdata']);
Route::get('/customer/{customerId}', [AuthorisationController::class, 'getCustomerById']);

Route::post('getsupport', [SupportController::class, 'getSupport']);
Route::post('getsupportPage', [SupportController::class, 'getSupportPage']);   

Route::post('category', [CategoryController::class, 'category']);
Route::post('categoryProducts', [CategoryController::class, 'categoryProducts']);

Route::post('productDetails', [ProductController::class, 'productDetails']);
Route::post('allpetcateg', [PetController::class, 'allPetCateg']);


Route::post('dashboard', [DashboardController::class, 'dashboard']);
Route::post('featuredproducts', [DashboardController::class, 'featuredProducts']);

Route::post('cartProducts', [CartController::class, 'cartProducts']);
Route::post('addcart', [CartController::class, 'addcart']);
Route::post('deletecartitem', [CartController::class, 'deleteCartItem']);

Route::post('adoptioninterest', [AdoptionController::class, 'adoptionInterest']);
Route::post('listadoption', [AdoptionController::class, 'listAdoption']);
Route::post('listMyAdoption', [AdoptionController::class, 'listMyAdoption']);
Route::post('addpetadoption', [AdoptionController::class, 'addPetAdoption']);
Route::post('petadoptiondetails', [AdoptionController::class, 'petAdoptionDetails']);
Route::post('updatepetadoption', [AdoptionController::class, 'updatePetAdoption']);
Route::post('deleteadoptpet', [AdoptionController::class, 'deleteAdoptPet']);
Route::post('updatepetadoptionImage', [AdoptionController::class, 'updatePetAdoptionImage']);  
Route::post('updateRemovepetadoptionImage', [AdoptionController::class, 'updateRemovePetAdoptionImage']);
Route::post('adoption-name', [AdoptionController::class, 'adoptionName']);
Route::post('addForAdoption', [AdoptionController::class, 'addForAdoption']);
Route::post('getInterestedPeople', [AdoptionController::class, 'getInterestedPeople']);

Route::post('wishlist', [WishlistController::class, 'wishlist']);
Route::post('makewish', [WishlistController::class, 'makewish']);
Route::post('deletewisheditem', [WishlistController::class, 'deletewisheditem']);
Route::post('searchitems', [WishlistController::class, 'searchitems']);

Route::post('addAddress', [AddressController::class, 'addAddress']);
Route::post('addressList', [AddressController::class, 'addressList']);
Route::post('stateList', [AddressController::class, 'stateList']);      
Route::post('payment', [PaymentController::class, 'payment']);

Route::post('orderProduct', [OrderController::class, 'orderProduct']);      
Route::post('loadorderhistory', [OrderController::class, 'loadorderhistory']);

Route::get('latestproduct', [ProductController::class, 'latestProduct']);
Route::get('featuredpro', [ProductController::class, 'featuredpro']);      
Route::post('featuredproducts', [ProductController::class, 'featuredproducts']);
Route::post('featuredproductslist', [ProductController::class, 'featuredproductsList']);
Route::get('special-product-list', [ProductController::class, 'specialProductList']);
Route::post('getlowerhigher', [ProductController::class, 'getlowerhigher']);
Route::post('filtered-products', [ProductController::class, 'filteredProducts']);

Route::post('addpet', [PetController::class, 'addPet']);  
Route::post('listpet', [PetController::class, 'listPet']);
Route::post('viewpet', [PetController::class, 'viewPet']);
Route::post('geteditpet', [PetController::class, 'getEditPet']);
Route::post('updatepet', [PetController::class, 'updatePet']);
Route::post('deletepet', [PetController::class, 'deletePet']);
Route::post('deleteMyPet', [PetController::class, 'deleteMyPet']);
Route::post('show-pet-details', [PetController::class, 'showPetDetails']);
Route::post('pet-chat-info', [PetController::class, 'petChatInfo']);

Route::get('animalbreed', [AnimalController::class, 'animalBreed']);
Route::post('breed', [AnimalController::class, 'breed']);
Route::post('breed2', [AnimalController::class, 'breed2']);

Route::post('addInterested', [InterestController::class, 'addInterested']); 
Route::post('deleteUser', [InterestController::class, 'deleteUsr']);

Route::post('save-token', [TokenController::class, 'saveToken']);     

Route::post('new-chats', [ChatController::class, 'newChats']);
Route::post('friends', [ChatController::class, 'friends']);
Route::post('chat_data', [ChatController::class, 'chat_data']);
Route::post('seenStatus', [ChatController::class, 'seenStatus']);
Route::post('saveMessage', [ChatController::class, 'saveMessage']);
Route::post('deleteEmpty', [ChatController::class, 'deleteEmpty']);   
Route::post('deleteChat', [ChatController::class, 'deleteChat']);     
Route::post('chatlist', [ChatController::class, 'chatlist']);     //\\
Route::post('loadchat', [ChatController::class, 'loadchat']);     //\\

Route::post('send-rescue-fcm', [NotificationController::class, 'sendRescueFCM']);
Route::post('send-fcm/{pageType}/{pageId}/{senderId}/{message}', [NotificationController::class, 'sendFCM']);
Route::post('productnotification', [NotificationController::class, 'sendProductNotification']);    //\\   ❌fcm token required

Route::post('updateRemoveRescuePetImage', [RescuePetController::class, 'updateRemoveRescuePetImage']);   
Route::get('rescueFields', [RescuePetController::class, 'addRescueFields']);
Route::post('rescueList', [RescuePetController::class, 'rescueList']); 
Route::post('add-rescue-pet', [RescuePetController::class, 'addRescuePet']);
Route::post('showrescuepet', [RescuePetController::class, 'showRescuePet']);
Route::post('editrescuepet', [RescuePetController::class, 'editRescuePet']);
Route::post('updaterescueimage', [RescuePetController::class, 'updateRescueImage']);
Route::delete('deleterescuepet', [RescuePetController::class, 'deleteRescuePet']); 

Route::get('colors', [ColorController::class, 'getColors']);

Route::post('filter', [FilterController::class, 'filter']);
Route::post('filter-by-group', [FilterController::class, 'getFiltersByGroup']);
Route::get('adoption-filter', [FilterController::class, 'adoptionFilter']);
Route::post('get-filters', [FilterController::class, 'getFilters']); 
Route::get('rescue-filter', [FilterController::class, 'rescueFilter']);
Route::get('rescue-filters', [FilterController::class, 'rescueFilters']);
Route::get('getoptions', [FilterController::class, 'getOptions']);   //\\

Route::post('bloglist', [BlogController::class, 'bloglist']);
Route::post('blog', [BlogController::class, 'blog']); 
Route::post('blogliked', [BlogController::class, 'BlogLiked']);
Route::post('loadcomment', [BlogController::class, 'loadComment']); 
Route::post('loadblogcomment', [BlogController::class, 'loadBlogComment']);
Route::post('postblogcomment', [BlogController::class, 'postBlogComment']);
Route::post('postcomment', [BlogController::class, 'postComment']);
Route::post('deletecomment', [BlogController::class, 'deleteComment']);
Route::post('searchblogs', [BlogController::class, 'searchBlogs']);      //\\

Route::post('listVets', [VetController::class, 'listVets']);
Route::post('loadvetdetails', [VetController::class, 'loadVetDetails']);
Route::post('sendvetreview', [VetController::class, 'sendVetReview']);

Route::post('loadtrainingdetails', [TrainerController::class, 'loadTrainingDetails']);
Route::post('list-trainer', [TrainerController::class, 'listTrainer']);

Route::post('loadgroomingdetails', [GroomingController::class, 'loadGroomingDetails']);
Route::post('loadreviews', [GroomingController::class, 'loadReviews']);
Route::post('list-grooming', [GroomingController::class, 'listGrooming']);

Route::post('shelterlist', [ShelterController::class, 'shelterList']);
Route::post('shelterdetails', [ShelterController::class, 'shelterDetails']);
Route::post('addshelter', [ShelterController::class, 'addShelter']);
Route::post('editshelter', [ShelterController::class, 'editShelter']);
Route::post('update-shelter-image', [ShelterController::class, 'updateShelterImage']);
Route::post('delete-shelter', [ShelterController::class, 'deleteShelter']);
Route::post('fosterdetails', [FosterController::class, 'fosterdetails']);    //\\
Route::post('fosterlist', [FosterController::class, 'fosterList']);    //\\

Route::post('add-cities-rescued', [RescuePetController::class, 'addCitiesRescued']);
Route::post('add-cities-rescued-edit', [RescuePetController::class, 'addCitiesRescuedEdit']);
Route::post('remove-cities-rescued-edit', [RescuePetController::class, 'removeCitiesRescuedEdit']);
Route::post('get-cities-rescued', [RescuePetController::class, 'getCitiesRescued']); 
Route::post('get-rescued-cities', [RescuePetController::class, 'getRescuedCities']);
Route::post('rescue-marked', [RescuePetController::class, 'rescueMarked']);
Route::post('/mark-rescue', [RescuePetController::class, 'marked']);
Route::post('/toggle-check', [RescuePetController::class, 'toggleCheck']);


Route::post('/load-states', [CityController::class, 'loadState']);
Route::post('/load-districts', [CityController::class, 'loadDistrict']);
Route::post('/load-cities', [CityController::class, 'loadCities']);
Route::post('load-state', [CityController::class, 'loadState']);
Route::post('load-city', [CityController::class, 'loadCity']);
Route::post('load-my-city', [CityController::class, 'loadMyCity']);
Route::post('search-city', [CityController::class, 'searchCity']);
Route::post('/add-cities-link', [CityController::class, 'addCitiesLink']);
Route::delete('/delete-city', [CityController::class, 'deleteCity']);

Route::post('/notification-list', [NotificationController::class, 'notificationList']);
Route::post('/clear-notification', [NotificationController::class, 'clearNotification']);
Route::post('/delete-notification', [NotificationController::class, 'deleteNotification']);
Route::post('/save-notification', [NotificationController::class, 'saveNotification']);

Route::post('loaddonationhistory', [DonationController::class, 'loadDonationHistory']);   //\\
Route::post('makedonation', [DonationController::class, 'makeDonation']);   //\\

Route::get('/adoptionImage/{imageName}', function ($imageName) {
    $path = public_path('adoptionImage/' . $imageName);

    if (!file_exists($path)) {
        abort(404); // Return a 404 if the file does not exist
    }

    return response()->file($path);
});

Route::get('/test', function () {
    return response()->json(['success' => true]);
});