<?php
//Fonction de sécurisation des entrées utilisateurs
function securize($p) {
    $v = htmlspecialchars($p); //Convertir les caractères spéciaux
    $v = trim($v); //Supprimer les espaces dans la requête
    $v = rtrim($v); //Supprimer les espaces à la fin de la requête
    $v = strtolower($v); //Tout mettre en minuscule
    $v = strip_tags($v); //Supprimer les balises html dans la requête
    $v = stripslashes($v); //Supprimer les slash dans la requête
    $v = stripcslashes($v); //Supprimer les backslash dans la requête
    return $v;
}

//Fonction de requête 
function request() {
	global $tool, $term;
	$file = "results/$term.html";
    shell_exec("echo tools.sh $tool $term > pipe/pipe");
	//header("Location: loader.html");
	while (!file_exists("$file")) {
		clearstatcache();
	}
	header("Location: $file");
	die();
}

//Choix de l'outil
if (isset($_POST["search"])) {
	$term = securize($_POST['search']);
	if (!empty($term)) {
		if ($_POST["tool"] == "ghunt") {
			$tool = "a";
			request();
        } elseif ($_POST["tool"] == "holehe") {
			$tool = "b";
			request();
        } elseif ($_POST["tool"] == "sherlock") {
			$tool = "c";
			request();
        } elseif ($_POST["tool"] == "profil3r") {
			$tool = "d";
			request();
        } elseif ($_POST["tool"] == "phoneinfoga") {
			$tool = "e";
			request();
		} else {
			echo 'Il faut selectionner au moins un outil';
			die();			
		}
	} else {
		echo 'La nature a horreur du vide, entrez un terme de recherche';
		die();
	}
}
?>